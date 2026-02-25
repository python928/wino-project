import random
import re

from django.conf import settings


def normalize_phone(phone: str) -> str:
	"""
	Normalize Algeria phone numbers to E.164 format.
	Accepted formats:
	- 0XXXXXXXXX (10 digits, must start with 0) -> +213XXXXXXXXX
	- +213XXXXXXXXX
	- 213XXXXXXXXX
	"""
	raw = (phone or '').strip()
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

	# Local Algeria format must be 10 digits and start with 0
	if len(digits) == 10 and digits.startswith('0') and digits.isdigit():
		return f"+213{digits[1:]}"

	return ''


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
