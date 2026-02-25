import random
import re

from django.conf import settings


def normalize_phone(phone: str) -> str:
	"""
	Normalize input to a Twilio-friendly E.164-like value.
	- strips spaces and punctuation
	- if starts with 0, assumes Algeria (+213)
	- if missing +, prefixes +
	"""
	raw = (phone or '').strip()
	if not raw:
		return ''

	digits = re.sub(r'[^\d+]', '', raw)
	if digits.startswith('00'):
		digits = f"+{digits[2:]}"
	elif digits.startswith('0'):
		digits = f"+213{digits[1:]}"
	elif not digits.startswith('+'):
		digits = f"+{digits}"

	return digits


def generate_otp_code() -> str:
	return f"{random.randint(0, 999999):06d}"


def send_otp_sms(phone: str, code: str) -> None:
	account_sid = getattr(settings, 'TWILIO_ACCOUNT_SID', '')
	auth_token = getattr(settings, 'TWILIO_AUTH_TOKEN', '')
	from_number = getattr(settings, 'TWILIO_FROM_NUMBER', '')

	if not account_sid or not auth_token or not from_number:
		raise RuntimeError('Twilio credentials are not configured')

	try:
		from twilio.base.exceptions import TwilioRestException
		from twilio.rest import Client
	except ImportError as exc:
		raise RuntimeError('Twilio SDK is not installed on server') from exc

	client = Client(account_sid, auth_token)
	body = f"Topri verification code: {code}. It expires in 5 minutes."
	try:
		client.messages.create(
			body=body,
			from_=from_number,
			to=phone,
		)
	except TwilioRestException as exc:
		raise RuntimeError(str(exc)) from exc
