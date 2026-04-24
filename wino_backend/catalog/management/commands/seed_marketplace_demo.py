import random
import string
import urllib.error
import urllib.request
from datetime import timedelta
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.management.base import BaseCommand
from django.db import transaction
from django.utils import timezone

from catalog.models import (
	Category,
	Pack,
	PackImage,
	PackProduct,
	Product,
	ProductImage,
	ProductReport,
	Promotion,
	Review,
)
from users.models import StoreReport

User = get_user_model()


CATEGORY_SEED = [
	{
		"name_en": "Electronics",
		"name_fr": "Electronique",
		"name_ar": "الكترونيات",
		"icon_code_point": "e8cc",  # shopping_cart
		"scarcity_level": 4,
	},
	{
		"name_en": "Fashion",
		"name_fr": "Mode",
		"name_ar": "موضة",
		"icon_code_point": "eb44",  # checkroom
		"scarcity_level": 3,
	},
	{
		"name_en": "Home Appliances",
		"name_fr": "Electromenager",
		"name_ar": "اجهزة منزلية",
		"icon_code_point": "e429",  # kitchen
		"scarcity_level": 5,
	},
	{
		"name_en": "Furniture",
		"name_fr": "Meubles",
		"name_ar": "اثاث",
		"icon_code_point": "f1c5",  # chair_alt
		"scarcity_level": 6,
	},
	{
		"name_en": "Beauty",
		"name_fr": "Beaute",
		"name_ar": "جمال",
		"icon_code_point": "e3be",  # face_retouching_natural
		"scarcity_level": 2,
	},
	{
		"name_en": "Sports",
		"name_fr": "Sport",
		"name_ar": "رياضة",
		"icon_code_point": "eb45",  # sports_soccer
		"scarcity_level": 5,
	},
	{
		"name_en": "Automotive",
		"name_fr": "Automobile",
		"name_ar": "سيارات",
		"icon_code_point": "e531",  # directions_car
		"scarcity_level": 8,
	},
	{
		"name_en": "Food",
		"name_fr": "Alimentaire",
		"name_ar": "مواد غذائية",
		"icon_code_point": "e56c",  # restaurant
		"scarcity_level": 1,
	},
	{
		"name_en": "Books",
		"name_fr": "Livres",
		"name_ar": "كتب",
		"icon_code_point": "e865",  # menu_book
		"scarcity_level": 4,
	},
	{
		"name_en": "Baby",
		"name_fr": "Bebe",
		"name_ar": "اطفال",
		"icon_code_point": "f6cf",  # stroller
		"scarcity_level": 3,
	},
	{
		"name_en": "Garden",
		"name_fr": "Jardin",
		"name_ar": "حديقة",
		"icon_code_point": "e030",  # grass
		"scarcity_level": 6,
	},
	{
		"name_en": "Office",
		"name_fr": "Bureau",
		"name_ar": "مستلزمات مكتبية",
		"icon_code_point": "e873",  # work
		"scarcity_level": 4,
	},
]


FIRST_NAMES = [
	"Yacine",
	"Amine",
	"Rayan",
	"Sami",
	"Nour",
	"Lina",
	"Yasmine",
	"Rim",
	"Imane",
	"Sarah",
	"Zineb",
	"Aya",
	"Karim",
	"Fares",
	"Ilyes",
]

STORE_TYPES = ["physical", "online"]
WILAYA_SAMPLES = [
	"Alger",
	"Oran",
	"Constantine",
	"Sidi Bel Abbes",
	"Setif",
	"Annaba",
	"Tlemcen",
	"Blida",
]

PRODUCT_NAME_SEED = [
	"Premium",
	"Smart",
	"Classic",
	"Eco",
	"Pro",
	"Max",
	"Ultra",
	"Comfort",
	"Daily",
]

REVIEW_COMMENTS = [
	"Good quality and fast delivery.",
	"Exactly as described.",
	"Very satisfied with this product.",
	"Price is fair for the quality.",
	"Packaging was clean and secure.",
	"Seller communication was great.",
	"Could be better, but still okay.",
	"Excellent value, recommended.",
]

REPORT_REASONS = ["spam", "fake", "fraud", "offensive", "other"]


def _random_phone(rng: random.Random) -> str:
	prefix = rng.choice(["05", "06", "07"])
	return prefix + "".join(rng.choices(string.digits, k=8))


def _internet_image_url(seed: str) -> str:
	# Public placeholder service with deterministic output by seed.
	return f"https://picsum.photos/seed/{seed}/900/900"


def _download_image_content(url: str, timeout: int = 20):
	req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
	with urllib.request.urlopen(req, timeout=timeout) as resp:
		return resp.read()


class Command(BaseCommand):
	help = (
		"Seed demo marketplace data: random users, multilingual categories with expressive icons, "
		"products with internet images, promotions/discounts, reviews, reports, and partial account verification."
	)

	def add_arguments(self, parser):
		parser.add_argument("--stores", type=int, default=18, help="Number of random store accounts.")
		parser.add_argument("--products-per-store", type=int, default=4, help="Products to create per store.")
		parser.add_argument("--reviews", type=int, default=140, help="How many reviews to generate.")
		parser.add_argument("--store-reports", type=int, default=35, help="How many store reports to generate.")
		parser.add_argument("--product-reports", type=int, default=70, help="How many product reports to generate.")
		parser.add_argument("--verify-ratio", type=float, default=0.35, help="Ratio of accounts to verify.")
		parser.add_argument("--seed", type=int, default=2026, help="Random seed for reproducible data.")
		parser.add_argument(
			"--clear-demo",
			action="store_true",
			help="Delete old demo users (username starts with demo_store_) before creating new data.",
		)

	@transaction.atomic
	def handle(self, *args, **options):
		rng = random.Random(options["seed"])

		if options["clear_demo"]:
			deleted, _ = User.objects.filter(username__startswith="demo_store_").delete()
			self.stdout.write(self.style.WARNING(f"Deleted previous demo records: {deleted}"))

		categories = self._seed_categories()
		self.stdout.write(self.style.SUCCESS(f"Categories ready: {len(categories)}"))

		stores = self._seed_stores(rng, options["stores"])
		self.stdout.write(self.style.SUCCESS(f"Stores created: {len(stores)}"))

		products = self._seed_products(rng, stores, categories, options["products_per_store"])
		self.stdout.write(self.style.SUCCESS(f"Products created: {len(products)}"))

		promotions_count, packs_count = self._seed_promotions_and_packs(rng, stores, products)
		self.stdout.write(self.style.SUCCESS(f"Promotions created: {promotions_count}"))
		self.stdout.write(self.style.SUCCESS(f"Discount packs created: {packs_count}"))

		reviews_count = self._seed_reviews(rng, stores, products, options["reviews"])
		self.stdout.write(self.style.SUCCESS(f"Reviews created: {reviews_count}"))

		store_reports_count = self._seed_store_reports(rng, stores, options["store_reports"])
		product_reports_count = self._seed_product_reports(rng, stores, products, options["product_reports"])
		self.stdout.write(self.style.SUCCESS(f"Store reports created: {store_reports_count}"))
		self.stdout.write(self.style.SUCCESS(f"Product reports created: {product_reports_count}"))

		verified_count = self._verify_some_accounts(rng, stores, options["verify_ratio"])
		self.stdout.write(self.style.SUCCESS(f"Verified accounts: {verified_count} / {len(stores)}"))

		self.stdout.write(self.style.SUCCESS("Demo marketplace seed completed successfully."))

	def _seed_categories(self):
		categories = []
		for item in CATEGORY_SEED:
			cat, _ = Category.objects.get_or_create(
				name_en=item["name_en"],
				defaults={
					"name": item["name_en"],
					"name_ar": item["name_ar"],
					"name_fr": item["name_fr"],
					"icon_code_point": item["icon_code_point"],
					"icon_font_family": "MaterialIcons",
					"icon_font_package": "",
					"scarcity_level": item["scarcity_level"],
				},
			)
			categories.append(cat)
		return categories

	def _seed_stores(self, rng: random.Random, count: int):
		stores = []
		base_join = timezone.now() - timedelta(days=180)

		for idx in range(1, count + 1):
			first_name = rng.choice(FIRST_NAMES)
			last_token = "".join(rng.choices(string.ascii_lowercase, k=4))
			username = f"demo_store_{idx:03d}_{last_token}"
			full_name = f"{first_name} Shop {idx}"
			email = f"{username}@demo.toprice.local"
			user = User.objects.create_user(
				username=username,
				email=email,
				password="Demo@12345",
				name=full_name,
				phone=_random_phone(rng),
			)

			user.address = f"{rng.randint(1, 220)} {rng.choice(WILAYA_SAMPLES)}"
			user.store_description = f"{full_name} offers curated products with competitive pricing."
			user.store_type = rng.choice(STORE_TYPES)
			user.show_phone_public = True
			user.show_social_public = True
			user.latitude = Decimal(str(round(22.0 + rng.random() * 14.0, 6)))
			user.longitude = Decimal(str(round(-8.0 + rng.random() * 17.0, 6)))
			user.date_joined = base_join + timedelta(days=rng.randint(1, 180))
			user.save()
			stores.append(user)

		return stores

	def _seed_products(self, rng: random.Random, stores, categories, products_per_store: int):
		products = []

		for store_idx, store in enumerate(stores, start=1):
			for p_idx in range(1, products_per_store + 1):
				category = rng.choice(categories)
				adjective = rng.choice(PRODUCT_NAME_SEED)
				product_name = f"{adjective} {category.name_en} Item {store_idx}-{p_idx}"

				product = Product.objects.create(
					store=store,
					category=category,
					name=product_name,
					description=f"{product_name} for daily use and reliable performance.",
					price=round(rng.uniform(600, 120000), 2),
					hide_price=rng.random() < 0.05,
					negotiable=rng.random() < 0.3,
					available_status=Product.AVAILABLE,
					delivery_available=rng.random() < 0.85,
					delivery_wilayas=rng.choice(WILAYA_SAMPLES),
				)
				products.append(product)

				image_seed = f"{store.username}-{product.id}"
				url = _internet_image_url(image_seed)
				try:
					content = _download_image_content(url)
					ProductImage.objects.create(
						product=product,
						image=ContentFile(content, name=f"demo_product_{product.id}.jpg"),
						is_main=True,
					)
				except (urllib.error.URLError, TimeoutError, ValueError) as exc:
					self.stdout.write(self.style.WARNING(f"Image skipped for product {product.id}: {exc}"))

		return products

	def _seed_promotions_and_packs(self, rng: random.Random, stores, products):
		now = timezone.now()
		promotions_count = 0
		packs_count = 0

		products_by_store = {}
		for product in products:
			products_by_store.setdefault(product.store_id, []).append(product)

		for store in stores:
			store_products = products_by_store.get(store.id, [])
			if not store_products:
				continue

			for idx in range(rng.randint(1, 3)):
				target_product = rng.choice(store_products)
				discount_pct = round(rng.uniform(5, 40), 2)
				Promotion.objects.create(
					store=store,
					product=target_product,
					name=f"Flash Offer {store.id}-{idx + 1}",
					description=f"Limited promotion with {discount_pct}% off.",
					percentage=discount_pct,
					is_active=True,
					start_date=now - timedelta(days=rng.randint(0, 4)),
					end_date=now + timedelta(days=rng.randint(4, 20)),
				)
				promotions_count += 1

			if len(store_products) >= 4:
				pack = Pack.objects.create(
					merchant=store,
					name=f"Bundle Pack {store.id}",
					description="Special discounted bundle for quick purchase.",
					discount=round(rng.uniform(500, 8000), 2),
					available_status=Pack.AVAILABLE,
					delivery_available=True,
					delivery_wilayas=rng.choice(WILAYA_SAMPLES),
				)
				target_products_count = 5 if rng.random() < 0.35 else 4
				chosen = rng.sample(store_products, k=min(target_products_count, len(store_products)))
				for prod in chosen:
					PackProduct.objects.create(pack=pack, product=prod, quantity=rng.randint(1, 3))

				try:
					content = _download_image_content(_internet_image_url(f"pack-{pack.id}"))
					PackImage.objects.create(
						pack=pack,
						image=ContentFile(content, name=f"demo_pack_{pack.id}.jpg"),
						is_main=True,
					)
				except (urllib.error.URLError, TimeoutError, ValueError) as exc:
					self.stdout.write(self.style.WARNING(f"Pack image skipped for {pack.id}: {exc}"))

				packs_count += 1

		return promotions_count, packs_count

	def _seed_reviews(self, rng: random.Random, stores, products, target_count: int):
		if len(stores) < 2 or not products:
			return 0

		created = 0
		max_attempts = target_count * 8
		attempts = 0

		while created < target_count and attempts < max_attempts:
			attempts += 1
			reviewer = rng.choice(stores)
			product = rng.choice(products)
			if product.store_id == reviewer.id:
				continue
			if Review.objects.filter(user=reviewer, product=product).exists():
				continue

			Review.objects.create(
				user=reviewer,
				store=product.store,
				product=product,
				rating=rng.randint(2, 5),
				comment=rng.choice(REVIEW_COMMENTS),
			)
			created += 1

		return created

	def _seed_store_reports(self, rng: random.Random, stores, target_count: int):
		if len(stores) < 2:
			return 0

		created = 0
		attempts = 0
		max_attempts = target_count * 8

		while created < target_count and attempts < max_attempts:
			attempts += 1
			reporter = rng.choice(stores)
			store = rng.choice(stores)
			if reporter.id == store.id:
				continue
			if StoreReport.objects.filter(reporter=reporter, store=store).exists():
				continue

			StoreReport.objects.create(
				reporter=reporter,
				store=store,
				reason=rng.choice(REPORT_REASONS),
				details="Auto-generated moderation report for testing.",
			)
			created += 1

		return created

	def _seed_product_reports(self, rng: random.Random, stores, products, target_count: int):
		if len(stores) < 2 or not products:
			return 0

		created = 0
		attempts = 0
		max_attempts = target_count * 10

		while created < target_count and attempts < max_attempts:
			attempts += 1
			reporter = rng.choice(stores)
			product = rng.choice(products)
			if reporter.id == product.store_id:
				continue
			if ProductReport.objects.filter(reporter=reporter, product=product).exists():
				continue

			ProductReport.objects.create(
				reporter=reporter,
				product=product,
				reason=rng.choice(REPORT_REASONS),
				details="Auto-generated product report for moderation tests.",
			)
			created += 1

		return created

	def _verify_some_accounts(self, rng: random.Random, stores, verify_ratio: float):
		if not stores:
			return 0

		ratio = min(max(verify_ratio, 0.0), 1.0)
		verify_count = max(1, int(len(stores) * ratio))
		chosen_ids = {u.id for u in rng.sample(stores, k=verify_count)}
		now = timezone.now()
		verifier = User.objects.filter(is_superuser=True).first()

		updated = 0
		for store in stores:
			if store.id in chosen_ids:
				store.verification_status = "verified"
				store.is_verified = True
				store.verified_at = now - timedelta(days=rng.randint(0, 20))
				store.verified_by = verifier
				store.verification_note = "Seed verification for QA testing."
				updated += 1
			else:
				store.verification_status = rng.choice(["none", "eligible", "pending"])
				store.is_verified = False
				store.verified_at = None
				store.verified_by = None
				store.verification_note = ""
			store.save(update_fields=[
				"verification_status",
				"is_verified",
				"verified_at",
				"verified_by",
				"verification_note",
			])

		return updated
