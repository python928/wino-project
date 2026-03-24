import re
import json
import random

from django.conf import settings

_ARABIC_DIGIT_MAP = str.maketrans(
	'٠١٢٣٤٥٦٧٨٩۰۱۲۳۴۵۶۷۸۹',
	'01234567890123456789',
)


def normalize_phone(phone: str) -> str:
	"""
	Normalize Algeria phone numbers to E.164 format.
	Accepted formats:
	- 0XXXXXXXXX (10 digits, must start with 0) -> +213XXXXXXXXX
	- +213XXXXXXXXX
	- 213XXXXXXXXX
	"""
	raw = (phone or '').strip().translate(_ARABIC_DIGIT_MAP)
	if not raw:
		return ''

	# Keep only digits and optional leading +
	cleaned = re.sub(r'[^\d+]', '', raw)
	if cleaned.startswith('+213'):
		local = cleaned[4:]
		if len(local) == 9 and local.isdigit():
			return cleaned
		return ''

	digits = cleaned.lstrip('+')
	if digits.startswith('213'):
		local = digits[3:]
		if len(local) == 9 and local.isdigit():
			return f"+{digits}"
		return ''

	# Local Algeria mobile format must be 10 digits and start with 05/06/07
	if (
		len(digits) == 10
		and digits.isdigit()
		and (digits.startswith('05') or digits.startswith('06') or digits.startswith('07'))
	):
		return f"+213{digits[1:]}"

	return ''


def generate_otp_code() -> str:
	# Temporary testing mode: use fixed OTP code.
	return "123456"


def send_otp_whatsapp(phone: str, code: str) -> None:
	account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', '')
	auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', '')
	whatsapp_from = getattr(settings, 'TWILIO_WHATSAPP_FROM', 'whatsapp:+14155238886')
	content_sid = getattr(settings, 'TWILIO_WHATSAPP_CONTENT_SID', '')

	if not account_sid or not auth_token or not whatsapp_from:
		raise RuntimeError('Twilio credentials are not configured')

	try:
		from twilio.base.exceptions import TwilioRestException
		from twilio.rest import Client
	except ImportError as exc:
		raise RuntimeError('Twilio SDK is not installed on server') from exc

	client = Client(account_sid, auth_token)
	whatsapp_to = f"whatsapp:{phone}"
	try:
		if content_sid:
			client.messages.create(
				from_=whatsapp_from,
				to=whatsapp_to,
				content_sid=content_sid,
				content_variables=json.dumps({'1': code}),
			)
		else:
			body = f"Wino verification code: {code}. It expires in 5 minutes."
			client.messages.create(
				body=body,
				from_=whatsapp_from,
				to=whatsapp_to,
			)
	except TwilioRestException as exc:
		# Trial accounts can send only to verified destination numbers.
		if getattr(exc, 'code', None) == 21608:
			raise RuntimeError(
				'Twilio Trial: الرقم غير موثق في Twilio WhatsApp Sandbox. '
				'قم بربط الرقم بالـ Sandbox أو فعّل الحساب.'
			) from exc
		raise RuntimeError('Twilio WhatsApp send failed') from exc


def send_otp_sms(phone: str, code: str) -> None:
	account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', '')
	auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', '')
	from_number = getattr(settings, 'TWILIO_FROM_NUMBER', '')

	if not account_sid or not auth_token or not from_number:
		raise RuntimeError('Twilio SMS is not configured')

	try:
		from twilio.base.exceptions import TwilioRestException
		from twilio.rest import Client
	except ImportError as exc:
		raise RuntimeError('Twilio SDK is not installed on server') from exc

	client = Client(account_sid, auth_token)
	body = f"Wino verification code: {code}. It expires in 5 minutes."
	try:
		client.messages.create(
			body=body,
			from_=from_number,
			to=phone,
		)
	except TwilioRestException as exc:
		if getattr(exc, 'code', None) == 21608:
			raise RuntimeError(
				'Twilio Trial SMS: الرقم غير موثّق في Twilio. '
				'قم بتوثيق الرقم أو فعّل الحساب.'
			) from exc
		raise RuntimeError('Twilio SMS send failed') from exc


def send_otp_message(phone: str, code: str) -> None:
	# Temporary testing mode: disable Twilio delivery.
	_ = phone, code
	return


def _username_base_from_name(name: str) -> str:
	"""Build username base with rule: name.replace(' ', '.')"""
	raw = (name or '').strip().lower()
	if not raw:
		return 'user'

	# Keep requested behavior: replace spaces with dots.
	base = raw.replace(' ', '.')
	# Also normalize any other whitespace runs to dots.
	base = re.sub(r'\s+', '.', base)
	# Keep only characters accepted by Django's username validator.
	base = re.sub(r'[^\w.@+-]', '', base, flags=re.UNICODE)
	base = re.sub(r'\.{2,}', '.', base).strip('.')
	return base or 'user'


def generate_unique_username_from_name(name: str) -> str:
	"""Generate unique username like: islam.ab1234, islam.ab1235, ..."""
	from django.contrib.auth import get_user_model
	User = get_user_model()

	base = _username_base_from_name(name)
	suffix = random.randint(1000, 9999)
	username = f"{base}{suffix}"
	while User.objects.filter(username=username).exists():
		suffix += 1
		username = f"{base}{suffix}"
	return username

from datetime import timedelta
from django.utils import timezone
from django.db import transaction


def check_and_grant_daily_coins(user):
	"""Grants daily login coins if 24 hours have passed since the last grant and balance is below target."""
	from .models import SystemSettings

	now = timezone.now()
	# Early exit if we already granted within 24h
	if user.last_daily_coin_grant and (now - user.last_daily_coin_grant) < timedelta(hours=24):
		return

	settings = SystemSettings.get_settings()
	target = settings.daily_login_coins

	with transaction.atomic():
		from .models import User
		locked_user = User.objects.select_for_update().get(id=user.id)

		# Check again under lock
		if locked_user.last_daily_coin_grant and (now - locked_user.last_daily_coin_grant) < timedelta(hours=24):
			return

		current_balance = locked_user.coins_balance
		if current_balance < target:
			from wallet.services import grant_coins
			diff = target - current_balance
			grant_coins(
				locked_user,
				amount=diff,
				reason='daily_login',
				related_model='User',
				related_id=locked_user.id,
			)

		locked_user.last_daily_coin_grant = now
		locked_user.last_login = now
		locked_user.save(update_fields=['last_daily_coin_grant', 'last_login'])
