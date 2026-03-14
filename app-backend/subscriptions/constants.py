DEFAULT_SUBSCRIPTION_RIB = '00799999004129827780'
DEFAULT_SUBSCRIPTION_INSTRUCTIONS = (
	'Send money to this RIB and submit payment confirmation.'
)

DEFAULT_PLAN_FEATURES = {
	'promotion_enabled': True,
	'promotion_max_active': 1,
	'promotion_max_duration_days': 10,
	'promotion_max_impressions': 800,
	'recommendation_priority_boost': 0,
	'ad_enabled': True,
	'ad_max_active': 1,
	'ad_max_duration_days': 7,
	'ad_max_impressions': 600,
	'ad_priority_boost': 5,
}

DEFAULT_SUBSCRIPTION_PLANS = [
	{
		'name': 'Dz Starter',
		'slug': 'dz-starter',
		'max_products': 30,
		'price': '1500.00',
		'duration_days': 30,
		'benefits': 'حتى 30 منشور شهريا\nعرض ترويجي واحد نشط\nدعم أساسي',
		'is_active': True,
		'plan_features': {
			'promotion_enabled': True,
			'promotion_max_active': 1,
			'promotion_max_duration_days': 10,
			'promotion_max_impressions': 1000,
			'recommendation_priority_boost': 5,
			'ad_enabled': True,
			'ad_max_active': 1,
			'ad_max_duration_days': 7,
			'ad_max_impressions': 800,
			'ad_priority_boost': 8,
		},
	},
	{
		'name': 'Dz Growth',
		'slug': 'dz-growth',
		'max_products': 90,
		'price': '3500.00',
		'duration_days': 30,
		'benefits': 'حتى 90 منشور شهريا\n3 عروض ترويجية نشطة\nتحسين ظهور أفضل',
		'is_active': True,
		'plan_features': {
			'promotion_enabled': True,
			'promotion_max_active': 3,
			'promotion_max_duration_days': 20,
			'promotion_max_impressions': 8000,
			'recommendation_priority_boost': 10,
			'ad_enabled': True,
			'ad_max_active': 3,
			'ad_max_duration_days': 15,
			'ad_max_impressions': 5000,
			'ad_priority_boost': 12,
		},
	},
	{
		'name': 'Dz Pro',
		'slug': 'dz-pro',
		'max_products': 220,
		'price': '7000.00',
		'duration_days': 30,
		'benefits': 'حتى 220 منشور شهريا\n10 عروض ترويجية نشطة\nأولوية قصوى ودعم سريع',
		'is_active': True,
		'plan_features': {
			'promotion_enabled': True,
			'promotion_max_active': 10,
			'promotion_max_duration_days': 30,
			'promotion_max_impressions': 50000,
			'recommendation_priority_boost': 20,
			'ad_enabled': True,
			'ad_max_active': 8,
			'ad_max_duration_days': 30,
			'ad_max_impressions': 30000,
			'ad_priority_boost': 18,
		},
	},
]
