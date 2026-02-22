"""
================================================================================
analytics/management/commands/seed_analytics.py
================================================================================
أمر إدارة لإنشاء بيانات تفاعل تجريبية (Seed Data) لاختبار نظام التوصيات.

الاستخدام:
  python manage.py seed_analytics
  python manage.py seed_analytics --user-id 1   (مستخدم محدد)
  python manage.py seed_analytics --clear        (مسح البيانات القديمة أولاً)

ما يفعله:
  1. يجلب المستخدمين والمنتجات الموجودة في قاعدة البيانات
  2. يُنشئ تفاعلات وهمية متنوعة (view/click/search/favorite/contact)
  3. يُشغّل update_profiles() تلقائيًا بعد إنشاء البيانات
  4. يطبع ملخصًا بما أُنشئ

مناسب لـ:
  - اختبار التوصيات قبل وجود مستخدمين حقيقيين
  - Demo أمام لجنة التحكيم
================================================================================
"""

from django.core.management.base import BaseCommand
from django.contrib.auth import get_user_model
import random

User = get_user_model()


class Command(BaseCommand):
	help = 'Seed analytics interaction data for testing recommendations.'

	def add_arguments(self, parser):
		parser.add_argument('--user-id', type=int, help='Seed for a specific user ID only')
		parser.add_argument('--clear', action='store_true', help='Clear existing interaction logs first')

	def handle(self, *args, **options):
		from catalog.models import Product, Category
		from analytics.models import InteractionLog
		from analytics.utils import log_user_event
		from analytics.scoring import update_all_profiles

		if options['clear']:
			deleted, _ = InteractionLog.objects.all().delete()
			self.stdout.write(self.style.WARNING(f'Cleared {deleted} interaction logs.'))

		# جلب المستخدمين
		if options.get('user_id'):
			users = User.objects.filter(id=options['user_id'])
		else:
			users = User.objects.all()[:5]

		if not users.exists():
			self.stdout.write(self.style.ERROR('No users found. Create at least one user first.'))
			return

		products = list(Product.objects.select_related('category')[:30])
		if not products:
			self.stdout.write(self.style.ERROR('No products found. Add some products first.'))
			return

		# أنواع التفاعلات مع أوزانها (كم مرة تظهر في الـ seed)
		action_pool = (
			['view'] * 6 +
			['click'] * 4 +
			['search'] * 3 +
			['favorite'] * 2 +
			['contact'] * 1 +
			['compare'] * 1
		)

		search_keywords = [
			'samsung galaxy', 'iphone', 'voiture occasion', 'appartement',
			'télévision', 'machine à laver', 'climatiseur', 'moto',
		]

		total_created = 0

		for user in users:
			# اختر مجموعة عشوائية من المنتجات لهذا المستخدم
			user_products = random.sample(products, min(15, len(products)))

			for product in user_products:
				action = random.choice(action_pool)

				metadata = {}
				if action == 'search':
					metadata = {'keyword': random.choice(search_keywords)}
				elif action == 'view':
					metadata = {'duration_seconds': random.randint(5, 120)}

				try:
					InteractionLog.objects.create(
						user=user,
						product=product,
						category=product.category,
						action=action,
						metadata=metadata,
					)
					total_created += 1
				except Exception as e:
					self.stdout.write(self.style.WARNING(f'Skipped: {e}'))

			# أضف بعض تفاعلات filter
			for _ in range(random.randint(2, 5)):
				InteractionLog.objects.create(
					user=user,
					action='filter_price',
					metadata={'min': random.choice([0, 2000, 5000]), 'max': random.choice([10000, 30000, 100000])},
				)
				total_created += 1

		self.stdout.write(self.style.SUCCESS(f'Created {total_created} interactions for {users.count()} user(s).'))

		# تحديث الـ profiles تلقائيًا
		self.stdout.write('Updating user profiles...')
		updated = update_all_profiles()
		self.stdout.write(self.style.SUCCESS(f'Updated {updated} user interest profile(s).'))
		self.stdout.write(self.style.SUCCESS(
			'Done! Test recommendations at: GET /api/analytics/recommendations/'
		))
