import random
import re
import json

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
	return f"{random.randint(0, 999999):06d}"


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
			body = f"Topri verification code: {code}. It expires in 5 minutes."
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
	body = f"Topri verification code: {code}. It expires in 5 minutes."
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
	channel = getattr(settings, 'TWILIO_OTP_CHANNEL', 'whatsapp').lower().strip()
	if channel == 'sms':
		send_otp_sms(phone, code)
		return
	if channel == 'both':
		whatsapp_error = None
		sms_error = None
		try:
			send_otp_whatsapp(phone, code)
		except Exception as exc:
			whatsapp_error = str(exc)
		try:
			send_otp_sms(phone, code)
		except Exception as exc:
			sms_error = str(exc)
		if whatsapp_error and sms_error:
			raise RuntimeError(f'WhatsApp error: {whatsapp_error} | SMS error: {sms_error}')
		return
	# default: whatsapp
	send_otp_whatsapp(phone, code)
