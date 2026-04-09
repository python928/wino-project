import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../constants/algeria_wilayas_baladiat.dart';

typedef _GeneratedResolver = String Function(AppLocalizations l10n);

class RuntimeTranslations {
  const RuntimeTranslations._();

  static String translate(BuildContext context, String text) {
    final generated = _generated[text];
    if (generated != null) {
      return generated(AppLocalizations.of(context));
    }

    final languageCode = Localizations.localeOf(context).languageCode;
    if (languageCode == 'fr') {
      return _translateWithLocationSupport(
        text: text,
        dictionary: _fr,
        languageCode: languageCode,
      );
    }
    if (languageCode == 'ar') {
      return _translateWithLocationSupport(
        text: text,
        dictionary: _ar,
        languageCode: languageCode,
      );
    }
    return text;
  }

  static final Set<String> _algeriaLocationNames = {
    ...algeriaWilayasBaladiat.keys,
    ...algeriaWilayasBaladiat.values.expand((v) => v),
  };

  static final Map<String, String> _canonicalLocationByNormalized = () {
    final map = <String, String>{};

    void add(String name) {
      final normalized = _normalizeLocationLookup(name);
      if (normalized.isEmpty) return;
      map.putIfAbsent(normalized, () => name);
    }

    for (final wilaya in algeriaWilayasBaladiat.keys) {
      add(wilaya);
    }
    for (final baladiyat in algeriaWilayasBaladiat.values) {
      for (final baladiya in baladiyat) {
        add(baladiya);
      }
    }

    return map;
  }();

  static const Map<String, String> _locationAliases = {
    // Common backend spelling.
    'alger': 'Algiers',
  };

  static const Map<String, String> _genericArabicLocationWords = {
    'centre': 'المركز',
    'center': 'المركز',
    'ville': 'مدينة',
    'commune': 'بلدية',
    'wilaya': 'ولاية',
  };

  static String _translateWithLocationSupport({
    required String text,
    required Map<String, String> dictionary,
    required String languageCode,
  }) {
    final direct = dictionary[text];
    if (direct != null) return direct;

    final canonical = _canonicalizeLocationName(text);
    if (canonical != null) {
      return _translateCanonicalLocation(
        canonical,
        dictionary,
        languageCode,
      );
    }

    final composite = _translateCompositeLocationExpression(
      raw: text,
      dictionary: dictionary,
      languageCode: languageCode,
    );
    if (composite != null) return composite;

    final phrase = _translateSpaceSeparatedLocationExpression(
      raw: text,
      dictionary: dictionary,
      languageCode: languageCode,
    );
    if (phrase != null) return phrase;

    // Legacy fallback: exact location token still auto-arabized.
    if (languageCode == 'ar' && _algeriaLocationNames.contains(text)) {
      return _arabizeAlgeriaName(text);
    }

    return text;
  }

  static String _translateCanonicalLocation(
    String canonical,
    Map<String, String> dictionary,
    String languageCode,
  ) {
    final mapped = dictionary[canonical];
    if (mapped != null) return mapped;
    if (languageCode == 'ar') return _arabizeAlgeriaName(canonical);
    return canonical;
  }

  static String? _translateCompositeLocationExpression({
    required String raw,
    required Map<String, String> dictionary,
    required String languageCode,
  }) {
    if (!raw.contains(',') && !raw.contains('،')) return null;

    final parts = raw
        .split(RegExp(r'[،,]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    if (parts.length < 2) return null;

    var changed = false;
    final translatedParts = <String>[];
    for (final part in parts) {
      final translated = _translateLocationChunk(
        part: part,
        dictionary: dictionary,
        languageCode: languageCode,
      );
      if (translated != part) changed = true;
      translatedParts.add(translated);
    }

    if (!changed) return null;
    return languageCode == 'ar'
        ? translatedParts.join('، ')
        : translatedParts.join(', ');
  }

  static String? _translateSpaceSeparatedLocationExpression({
    required String raw,
    required Map<String, String> dictionary,
    required String languageCode,
  }) {
    if (raw.contains(',') || raw.contains('،')) return null;
    if (!raw.contains(' ')) return null;

    final translated = _translateLocationChunk(
      part: raw,
      dictionary: dictionary,
      languageCode: languageCode,
    );

    if (translated == raw) return null;
    return translated;
  }

  static String _translateLocationChunk({
    required String part,
    required Map<String, String> dictionary,
    required String languageCode,
  }) {
    final canonical = _canonicalizeLocationName(part);
    if (canonical != null) {
      return _translateCanonicalLocation(canonical, dictionary, languageCode);
    }

    final words = part.split(RegExp(r'\s+'));
    if (words.length < 2) return part;

    var changed = false;
    final translatedWords = <String>[];
    for (final word in words) {
      final canonicalWord = _canonicalizeLocationName(word);
      if (canonicalWord != null) {
        translatedWords.add(
          _translateCanonicalLocation(canonicalWord, dictionary, languageCode),
        );
        changed = true;
        continue;
      }

      if (languageCode == 'ar') {
        final generic =
            _genericArabicLocationWords[_normalizeLocationLookup(word)];
        if (generic != null) {
          translatedWords.add(generic);
          changed = true;
          continue;
        }
      }

      translatedWords.add(word);
    }

    if (!changed) return part;
    return translatedWords.join(' ');
  }

  static String? _canonicalizeLocationName(String raw) {
    final normalized = _normalizeLocationLookup(raw);
    if (normalized.isEmpty) return null;

    final alias = _locationAliases[normalized];
    if (alias != null) return alias;

    return _canonicalLocationByNormalized[normalized];
  }

  static String _normalizeLocationLookup(String input) {
    return _stripDiacritics(input)
        .toLowerCase()
        .replaceAll(RegExp(r"[’'`´]"), ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String _arabizeAlgeriaName(String raw) {
    final normalized = raw
        .replaceAll("'", ' ')
        .replaceAll('-', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (normalized.isEmpty) return raw;

    final words = normalized.split(' ');
    final converted = words.map(_arabizeToken).where((w) => w.isNotEmpty);
    return converted.join(' ');
  }

  static String _arabizeToken(String token) {
    final cleaned = _stripDiacritics(token);
    final lower = cleaned.toLowerCase();

    // Common Algerian place-name morphemes.
    const lexicon = {
      'ain': 'عين',
      'ouled': 'أولاد',
      'oued': 'وادي',
      'sidi': 'سيدي',
      'beni': 'بني',
      'ben': 'بن',
      'bir': 'بئر',
      'el': 'ال',
      'bou': 'بو',
      'hassi': 'حاسي',
      'bordj': 'برج',
      'ksar': 'قصر',
      'djebel': 'جبل',
      'oum': 'أم',
      'ainn': 'عين',
      'in': 'إن',
    };

    final direct = lexicon[lower];
    if (direct != null) return direct;

    return _transliterateLatinWord(cleaned);
  }

  static String _stripDiacritics(String input) {
    return input
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('ë', 'e')
        .replaceAll('à', 'a')
        .replaceAll('â', 'a')
        .replaceAll('î', 'i')
        .replaceAll('ï', 'i')
        .replaceAll('ô', 'o')
        .replaceAll('ö', 'o')
        .replaceAll('û', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ç', 'c')
        .replaceAll('É', 'E')
        .replaceAll('È', 'E')
        .replaceAll('Ê', 'E')
        .replaceAll('Ë', 'E')
        .replaceAll('À', 'A')
        .replaceAll('Â', 'A')
        .replaceAll('Î', 'I')
        .replaceAll('Ï', 'I')
        .replaceAll('Ô', 'O')
        .replaceAll('Ö', 'O')
        .replaceAll('Û', 'U')
        .replaceAll('Ü', 'U')
        .replaceAll('Ç', 'C');
  }

  static String _transliterateLatinWord(String input) {
    if (input.isEmpty) return input;
    final s = input.toLowerCase();
    final out = StringBuffer();
    var i = 0;

    while (i < s.length) {
      String? take;
      String? mapped;

      if (i + 2 <= s.length) {
        final d = s.substring(i, i + 2);
        const digraph = {
          'ch': 'ش',
          'gh': 'غ',
          'kh': 'خ',
          'sh': 'ش',
          'th': 'ث',
          'dh': 'ذ',
          'ou': 'و',
          'aa': 'ا',
          'ee': 'ي',
          'oo': 'و',
          'ph': 'ف',
          'gn': 'ني',
          'dj': 'ج',
        };
        mapped = digraph[d];
        if (mapped != null) take = d;
      }

      if (mapped == null) {
        final c = s[i];
        const single = {
          'a': 'ا',
          'b': 'ب',
          'c': 'ك',
          'd': 'د',
          'e': 'ي',
          'f': 'ف',
          'g': 'غ',
          'h': 'ه',
          'i': 'ي',
          'j': 'ج',
          'k': 'ك',
          'l': 'ل',
          'm': 'م',
          'n': 'ن',
          'o': 'و',
          'p': 'ب',
          'q': 'ق',
          'r': 'ر',
          's': 'س',
          't': 'ت',
          'u': 'و',
          'v': 'ف',
          'w': 'و',
          'x': 'كس',
          'y': 'ي',
          'z': 'ز',
        };
        mapped = single[c] ?? c;
        take = c;
      }

      out.write(mapped);
      i += take!.length;
    }

    return out.toString();
  }

  static final Map<String, _GeneratedResolver> _generated = {
    'Back to home': (l10n) => l10n.commonBackToHome,
    'Cancel': (l10n) => l10n.commonCancel,
    'Close': (l10n) => l10n.close,
    'Continue': (l10n) => l10n.commonContinue,
    'Directions to store': (l10n) => l10n.directionsToStore,
    'Language': (l10n) => l10n.commonLanguage,
    'Loading...': (l10n) => l10n.commonLoading,
    'Map': (l10n) => l10n.mapLabel,
    'Next': (l10n) => l10n.commonNext,
    'No location available': (l10n) => l10n.locationUnavailable,
    'Not now': (l10n) => l10n.commonNotNow,
    'Open App Settings': (l10n) => l10n.settingsOpenApp,
    'Open Location Settings': (l10n) => l10n.settingsOpenLocation,
    'Open Settings': (l10n) => l10n.openSettings,
    'Open in Google Maps': (l10n) => l10n.openInGoogleMaps,
    'Retry': (l10n) => l10n.commonRetry,
    'Save': (l10n) => l10n.commonSave,
    'Search': (l10n) => l10n.commonSearch,
    'Skip': (l10n) => l10n.commonSkip,
    'Start': (l10n) => l10n.commonStart,
    'Location is disabled': (l10n) => l10n.locationDisabledTitle,
    'Enable location service (GPS) from settings to use directions.': (l10n) =>
        l10n.locationDisabledMessage,
    'Unable to open Google Maps': (l10n) => l10n.unableToOpenGoogleMaps,
  };

  static const Map<String, String> _fr = {
    'Add Product': 'Ajouter un produit',
    'Add Discount': 'Ajouter une réduction',
    'Add Pack': 'Ajouter un pack',
    'Ads': 'Annonces',
    'All': 'Tous',
    'Available': 'Disponible',
    'Back': 'Retour',
    'Back to home': 'Retour à l’accueil',
    'Birthday': 'Date de naissance',
    'Buy': 'Acheter',
    'Call': 'Appeler',
    'Camera': 'Caméra',
    'Cancel': 'Annuler',
    'Choose image source': 'Choisir la source de l’image',
    'City': 'Ville',
    'Clear': 'Effacer',
    'Close': 'Fermer',
    'Coin Payment': 'Paiement de pièces',
    'Coin Store': 'Boutique de pièces',
    'Coins': 'Pièces',
    'coins': 'pièces',
    'You need': 'Vous avez besoin de',
    'Balance': 'Solde',
    'Missing': 'Manquant',
    'DZD': 'DZD',
    'km': 'km',
    'Coordinates Locked': 'Coordonnées verrouillées',
    'Complete Your Profile': 'Complétez votre profil',
    'Name, birthday, gender and categories':
        'Nom, date de naissance, genre et catégories',
    'Male': 'Homme',
    'Female': 'Femme',
    'Select categories': 'Sélectionner des catégories',
    'selected': 'sélectionné',
    'Copy link': 'Copier le lien',
    'Copy number': 'Copier le numéro',
    'Create New Pack': 'Créer un nouveau pack',
    'Create Sponsored Ad': 'Créer une annonce sponsorisée',
    'Edit Sponsored Ad': 'Modifier l\'annonce sponsorisée',
    'Edit Discount': 'Modifier la réduction',
    'Select Pack to Sponsor': 'Sélectionner un pack à sponsoriser',
    'Select Discount to Sponsor': 'Sélectionner une réduction à sponsoriser',
    'Tap to select product...': 'Touchez pour sélectionner un produit...',
    'Tap to select pack to sponsor...':
        'Touchez pour sélectionner un pack à sponsoriser...',
    'Tap to select a product with active discount...':
        'Touchez pour sélectionner un produit avec réduction active...',
    'Tap to select product to sponsor...':
        'Touchez pour sélectionner le produit à sponsoriser...',
    'Ad Active': 'Annonce active',
    'Show this sponsored ad to customers':
        'Afficher cette annonce sponsorisée aux clients',
    'Show this discount to customers': 'Afficher cette réduction aux clients',
    'Saving...': 'Enregistrement...',
    'Save Changes': 'Enregistrer les modifications',
    'Launch Sponsored Ad': 'Lancer l\'annonce sponsorisée',
    'Apply Discount': 'Appliquer la réduction',
    'Delete Sponsored Ad?': 'Supprimer l\'annonce sponsorisée ?',
    'Delete Discount?': 'Supprimer la réduction ?',
    'This will remove the sponsored ad from this product.':
        'Cela supprimera l\'annonce sponsorisée de ce produit.',
    'This will remove the discount from this product.':
        'Cela supprimera la réduction de ce produit.',
    'Sponsored ad deleted successfully':
        'Annonce sponsorisée supprimée avec succès',
    'Discount deleted successfully': 'Réduction supprimée avec succès',
    'Failed to delete sponsored ad':
        'Échec de la suppression de l\'annonce sponsorisée',
    'Failed to delete discount': 'Échec de la suppression de la réduction',
    'Sponsored ad updated successfully':
        'Annonce sponsorisée mise à jour avec succès',
    'Discount edited successfully': 'Réduction modifiée avec succès',
    'Sponsored ad created successfully':
        'Annonce sponsorisée créée avec succès',
    'Sponsored': 'Sponsorisé',
    'View deal': 'Voir l\'offre',
    'Discount added successfully': 'Réduction ajoutée avec succès',
    'No active discounts found. Create a discount first.':
        'Aucune réduction active trouvée. Créez d\'abord une réduction.',
    'Please enter the number of ad impressions':
        'Veuillez saisir le nombre d\'impressions publicitaires',
    'Insufficient Ad View Coins. Need \$extraNeeded more impressions budget, available \$affordable.':
        'Pièces de vues pub insuffisantes. Il faut \$extraNeeded impressions de plus, disponible : \$affordable.',
    'am': 'h',
    'pm': 'h',
    'No hour selected': 'Aucune heure sélectionnée',
    'All day': 'Toute la journée',
    'Business hours': 'Heures de bureau',
    'All day (24h)': 'Toute la journée (24h)',
    'Business hours (8AM-7PM)': 'Heures de bureau (8h-19h)',
    'Select at least one hour': 'Sélectionnez au moins une heure',
    'Existing Sponsored Ad': 'Annonce sponsorisée existante',
    'Existing Discount': 'Réduction existante',
    'This product already has an ad campaign. Do you want to edit it?':
        'Ce produit a déjà une campagne publicitaire. Voulez-vous la modifier ?',
    'This product already has a discount. Do you want to edit it?':
        'Ce produit a déjà une réduction. Voulez-vous la modifier ?',
    'Start Date & Time': 'Date et heure de début',
    'End Date & Time': 'Date et heure de fin',
    'Please select a pack': 'Veuillez sélectionner un pack',
    'Please select a product': 'Veuillez sélectionner un produit',
    'Age range is invalid': 'La tranche d\'âge est invalide',
    'Select at least one hour to show your ad':
        'Sélectionnez au moins une heure pour afficher votre annonce',
    'Discount target requires a product with active discount.':
        'La cible réduction nécessite un produit avec une réduction active.',
    'Select at least one target wilaya':
        'Sélectionnez au moins une wilaya cible',
    'Choose target radius in km': 'Choisissez le rayon cible en km',
    'End time must be after start time':
        'L\'heure de fin doit être après l\'heure de début',
    'Duration exceeds the current limit (\$maxDays days).':
        'La durée dépasse la limite actuelle (\$maxDays jours).',
    'Failed to': 'Échec de',
    'save': 'enregistrer',
    'create': 'créer',
    'sponsored ad': 'annonce sponsorisée',
    'discount': 'réduction',
    'This discount is not available': 'Cette réduction n\'est pas disponible',
    'Sponsored Pack Summary': 'Résumé du pack sponsorisé',
    'Sponsored Discount Summary': 'Résumé de la réduction sponsorisée',
    'Sponsored Product Summary': 'Résumé du produit sponsorisé',
    'Current Price': 'Prix actuel',
    'Discount Percentage (%)': 'Pourcentage de réduction (%)',
    'Required': 'Obligatoire',
    'Invalid': 'Invalide',
    'Ad Impressions': 'Impressions publicitaires',
    'e.g. 5000': 'ex. 5000',
    'Current ad impressions to activate:':
        'Impressions pub actuelles à activer :',
    'Age From': 'Âge de',
    'Age To': 'Âge à',
    'Choose Radius (km)': 'Choisir le rayon (km)',
    'Sponsored ad will stay active until impressions are exhausted.':
        'L\'annonce sponsorisée restera active jusqu\'à épuisement des impressions.',
    'Select Product to Sponsor': 'Sélectionner un produit à sponsoriser',
    'Select products to sponsor': 'Sélectionner des produits à sponsoriser',
    'Select Product': 'Sélectionner un produit',
    'Select Target Wilayas': 'Sélectionner les wilayas cibles',
    'wilayas selected': 'wilayas sélectionnées',
    'Current Plan': 'Plan actuel',
    'Delete': 'Supprimer',
    'Delete Product?': 'Supprimer le produit ?',
    'Delete cover image?': 'Supprimer l’image de couverture ?',
    'Delete profile image?': 'Supprimer la photo de profil ?',
    'Delivery Available': 'Livraison disponible',
    'Discount': 'Réduction',
    'Discounts': 'Réductions',
    'Discover Plans': 'Découvrir les plans',
    'Edit': 'Modifier',
    'Edit Ad': 'Modifier l’annonce',
    'Edit Information': 'Modifier les informations',
    'Edit Profile': 'Modifier le profil',
    'Failed to load dashboard': 'Échec du chargement du tableau de bord',
    'Failed to load plans': 'Échec du chargement des plans',
    'Enable home delivery for this pack':
        'Activer la livraison à domicile pour ce pack',
    'English': 'Anglais',
    'Enter your full name': 'Entrez votre nom complet',
    'Favorite Categories': 'Catégories favorites',
    'Featured Packs': 'Packs en vedette',
    'Featured Stores': 'Magasins en vedette',
    'Follow': 'Suivre',
    'Follow a store to see it here': 'Suivez un magasin pour le voir ici',
    'Following': 'Suivi',
    'Français': 'Français',
    'Full Name': 'Nom complet',
    'Gallery': 'Galerie',
    'Gender': 'Genre',
    'Home': 'Accueil',
    'Latest Products': 'Derniers produits',
    'Load more': 'Voir plus',
    'Location': 'Localisation',
    'Select your location': 'Sélectionnez votre emplacement',
    'Tap to change': 'Touchez pour modifier',
    'Tap to choose location': 'Touchez pour choisir un emplacement',
    'Logout': 'Se déconnecter',
    'Mark all as read': 'Tout marquer comme lu',
    'New Price:': 'Nouveau prix :',
    'New Price': 'Nouveau prix',
    'Schedule': 'Calendrier',
    'Tap to select date': 'Touchez pour sélectionner une date',
    'at': 'à',
    'New Product': 'Nouveau produit',
    'No ads found in this period.':
        'Aucune annonce trouvée pour cette période.',
    'No baladiya found': 'Aucune baladiya trouvée',
    'No content here yet': 'Aucun contenu ici pour le moment',
    'No followed stores': 'Aucun magasin suivi',
    'No manual follow-up needed': 'Aucun suivi manuel nécessaire',
    'No notifications': 'Aucune notification',
    'No notifications yet': 'Aucune notification pour le moment',
    'No packs available for advertising.':
        'Aucun pack disponible pour la publicité.',
    'No packs available yet.': 'Aucun pack disponible pour le moment.',
    'No purchase requests yet.': 'Aucune demande d’achat pour le moment.',
    'No transactions yet.': 'Aucune transaction pour le moment.',
    'No wilaya found': 'Aucune wilaya trouvée',
    'Note (optional)': 'Note (optionnelle)',
    'Nearby': 'À proximité',
    'new notifications': 'nouvelles notifications',
    'Notifications': 'Notifications',
    'Notification': 'Notification',
    'Notifications coming soon': 'Notifications bientôt disponibles',
    'Filters coming soon': 'Filtres bientôt disponibles',
    'New User Offer': 'Offre nouvel utilisateur',
    'OK': 'OK',
    'Open Settings': 'Ouvrir les paramètres',
    'Original Price:': 'Prix initial :',
    'Pack': 'Pack',
    'Pack Details': 'Détails du pack',
    'Payment': 'Paiement',
    'Registration failed': 'Échec de l’inscription',
    'Payment note (optional)': 'Note de paiement (optionnelle)',
    'Payment proof images': 'Images de preuve de paiement',
    'Please select wilaya and baladiya':
        'Veuillez sélectionner la wilaya et la baladiya',
    'Product': 'Produit',
    'Product Details': 'Détails du produit',
    'Products': 'Produits',
    'Posts': 'Publications',
    'Followers': 'Abonnés',
    'Rating': 'Note',
    'Contact Store': 'Contacter le magasin',
    'Add Favorite': 'Ajouter aux favoris',
    'Remove Favorite': 'Retirer des favoris',
    'Added to favorites': 'Ajouté aux favoris',
    'Cover image updated successfully':
        'Image de couverture mise à jour avec succès',
    'Failed to update cover image':
        'Échec de la mise à jour de l\'image de couverture',
    'Cover image deleted successfully':
        'Image de couverture supprimée avec succès',
    'Failed to delete cover image':
        'Échec de la suppression de l\'image de couverture',
    'Profile image updated successfully':
        'Image de profil mise à jour avec succès',
    'Failed to update image': 'Échec de la mise à jour de l\'image',
    'Profile image deleted successfully':
        'Image de profil supprimée avec succès',
    'Failed to delete profile image':
        'Échec de la suppression de l\'image de profil',
    'Logged out successfully!': 'Déconnexion réussie !',
    'Log in to follow stores': 'Connectez-vous pour suivre les magasins',
    'Followed store': 'Magasin suivi',
    'Unfollowed store': 'Magasin non suivi',
    'Failed to update follow': 'Échec de la mise à jour du suivi',
    'Rate this store': 'Évaluer ce magasin',
    'Write Review': 'Écrire un avis',
    'Removed from favorites': 'Retiré des favoris',
    'Failed to update favorite': 'Échec de mise à jour des favoris',
    'Failed to update favorites': 'Échec de la mise à jour des favoris',
    'Log in to save favorites': 'Connectez-vous pour enregistrer les favoris',
    'Products with Discounts': 'Produits avec réductions',
    'Top Discounts': 'Meilleures reductions',
    'Top Products': 'Meilleurs produits',
    'Top Packs': 'Meilleurs packs',
    'Product link copied': 'Lien du produit copié',
    'Review submitted successfully': 'Avis envoyé avec succès',
    'Failed to submit review': 'Échec de l\'envoi de l\'avis',
    'Please upload at least one payment proof.':
        'Veuillez télécharger au moins une preuve de paiement.',
    'Payment request': 'Demande de paiement',
    'is pending server approval.':
        'est en attente de validation par le serveur.',
    'Coins are added after approval.':
        'Les pièces sont ajoutées après approbation.',
    'Removed pack products from favorites':
        'Produits du pack retirés des favoris',
    'Added pack products to favorites': 'Produits du pack ajoutés aux favoris',
    'An error occurred': 'Une erreur est survenue',
    'No image selected': 'Aucune image sélectionnée',
    'Profile picture updated successfully':
        'Photo de profil mise à jour avec succès',
    'Failed to delete image': 'Échec de la suppression de l\'image',
    'Please fill in all required fields':
        'Veuillez remplir tous les champs obligatoires',
    'Data saved successfully': 'Données enregistrées avec succès',
    'Error saving data': 'Erreur lors de l\'enregistrement des données',
    'Failed to update cover': 'Échec de la mise à jour de la couverture',
    'Failed to delete cover': 'Échec de la suppression de la couverture',
    'Please enter your name': 'Veuillez saisir votre nom',
    'Profile': 'Profil',
    'Promotion Details': 'Détails de la promotion',
    'Quantity': 'Quantité',
    'Rating: ': 'Note : ',
    'Regular Price:': 'Prix normal :',
    'Regular Total:': 'Total normal :',
    'Report Store': 'Signaler le magasin',
    'Report Offer': 'Signaler l’offre',
    'Report Pack': 'Signaler le pack',
    'Report': 'Signaler',
    'Report Product': 'Signaler le produit',
    'Duplicate / spam listing': 'Annonce en double / spam',
    'Duplicate / spam store': 'Magasin en double / spam',
    'Fake / counterfeit product': 'Produit faux / contrefait',
    'Fake store / no real location': 'Faux magasin / aucune adresse réelle',
    'Scam / asked for prepayment': 'Arnaque / demande de prépaiement',
    'Offensive / prohibited content': 'Contenu offensant / interdit',
    'Other (price mismatch, wrong info)':
        'Autre (prix incorrect, informations erronées)',
    'Other (wrong info, bad service)':
        'Autre (mauvaises infos, mauvais service)',
    'Recommended for you': 'Recommandé pour vous',
    'Request received': 'Demande reçue',
    'Request submitted': 'Demande envoyée',
    'Save': 'Enregistrer',
    'Saved': 'Enregistré',
    'Save Failed': 'Échec de l’enregistrement',
    'Savings': 'Économies',
    'Search categories...': 'Rechercher des catégories...',
    'Search my posts...': 'Rechercher mes publications...',
    'Search packs...': 'Rechercher des packs...',
    'Search products, stores...': 'Rechercher des produits, magasins...',
    'Search products...': 'Rechercher des produits...',
    'Search Radius': 'Rayon de recherche',
    'Your Coins': 'Vos pièces',
    'Publishing Costs': 'Coûts de publication',
    'Purchase Requests': 'Demandes d\'achat',
    'Recent Transactions': 'Transactions récentes',
    'Product Post': 'Publication produit',
    'Pack Post': 'Publication pack',
    'Promotion Post': 'Publication promotion',
    'coin': 'pièce',
    'Impressions': 'Impressions',
    'Clicks': 'Clics',
    'Active Ads': 'Annonces actives',
    'Advertised': 'Sponsorisé',
    'Views': 'Vues',
    '14D': '14J',
    'Ad View Coins balance:': 'Solde de pièces de vues pub :',
    'Ad View:': 'Vue pub :',
    'ad View:': 'Vue pub :',
    'ad view': 'vue pub',
    'Cost per impression:': 'Coût par impression :',
    'Current max impressions you can activate:':
        'Nombre maximal d\'impressions activables :',
    'Selected hours': 'Heures sélectionnées',
    'Product Create': 'Créer un produit',
    'product create': 'créer un produit',
    'See All': 'Voir tout',
    'View All': 'Voir tout',
    'Select Hours': 'Sélectionner les heures',
    'Select product to add...': 'Sélectionner un produit à ajouter...',
    'Add details (optional)': 'Ajouter des détails (optionnel)',
    'Send Report': 'Envoyer le signalement',
    'Send Product': 'Envoyer le produit',
    'Send request': 'Envoyer la demande',
    'Share': 'Partager',
    'Share Product': 'Partager le produit',
    'Share Store': 'Partager le magasin',
    'Show At Hour': 'Afficher à l’heure',
    'Show Price': 'Afficher le prix',
    'Show Product QR': 'Afficher le QR du produit',
    'Show WhatsApp/social buttons': 'Afficher les boutons WhatsApp/réseaux',
    'Show call button': 'Afficher le bouton d’appel',
    'Show more': 'Afficher plus',
    'Show this pack to customers in your store':
        'Afficher ce pack aux clients de votre magasin',
    'Social Accounts': 'Comptes sociaux',
    'Store Location': 'Emplacement du magasin',
    'Stores': 'Magasins',
    'Submit Review': 'Envoyer un avis',
    'Reviews': 'Avis',
    'Your Review': 'Votre avis',
    'Submit payment request': 'Soumettre une demande de paiement',
    'This action cannot be undone.': 'Cette action est irréversible.',
    'Delete your review?': 'Supprimer votre avis ?',
    'This will permanently remove your review.':
        'Cela supprimera définitivement votre avis.',
    'This item is no longer available.': 'Cet élément n’est plus disponible.',
    'This will remove your current cover image.':
        'Cela supprimera votre image de couverture actuelle.',
    'This will remove your current profile image.':
        'Cela supprimera votre photo de profil actuelle.',
    'Total': 'Total',
    'Total Product Prices:': 'Prix total des produits :',
    'Transfer reference / notes': 'Référence de virement / notes',
    'Upload 1 to 3 images. Your request will be reviewed by admin.':
        'Téléchargez 1 à 3 images. Votre demande sera examinée par l’administrateur.',
    'Verified': 'Vérifié',
    'Verify Code': 'Vérifier le code',
    'Verify': 'Vérifier',
    'Sign in with phone number': 'Se connecter avec un numéro de téléphone',
    'Sign In With Phone': 'Se connecter avec téléphone',
    'Enter your Algerian number (0XXXXXXXXX)':
        'Entrez votre numéro algérien (0XXXXXXXXX)',
    'Phone Number': 'Numéro de téléphone',
    'Please enter your phone number':
        'Veuillez entrer votre numéro de téléphone',
    'Use format 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX':
        'Utilisez le format 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX',
    'Send Code': 'Envoyer le code',
    'Failed to send verification code.':
        'Échec de l\'envoi du code de vérification.',
    'Server connection failed. Please try again.':
        'Échec de connexion au serveur. Veuillez réessayer.',
    'Enter the 6-digit code': 'Entrez le code à 6 chiffres',
    'OTP verification failed.': 'La vérification du code OTP a échoué.',
    'Verification code resent': 'Code de vérification renvoyé',
    'Failed to resend code': 'Échec du renvoi du code',
    'We sent a 6-digit code to': 'Nous avons envoyé un code à 6 chiffres à',
    'Resend in': 'Renvoyer dans',
    'Resend code': 'Renvoyer le code',
    'Skip (Prototype)': 'Passer (Prototype)',
    'Your current location': 'Votre position actuelle',
    'Algeria': 'Algérie',
    'Session expired. Please login again.':
        'Session expirée. Veuillez vous reconnecter.',
    'No internet connection or server is unreachable':
        'Aucune connexion Internet ou serveur injoignable',
    'Connection timed out. Please try again.':
        'Délai de connexion dépassé. Veuillez réessayer.',
    'Server error. Please try again later.':
        'Erreur serveur. Veuillez réessayer plus tard.',
    'Invalid response format from server': 'Format de réponse serveur invalide',
    'Request failed': 'La requête a échoué',
    'We are reviewing your image...': 'Nous examinons votre image...',
    'WhatsApp': 'WhatsApp',
    'Write your review...': 'Écrivez votre avis...',
    'Log in to add a review': 'Connectez-vous pour ajouter un avis',
    'Log in first to report products':
        'Connectez-vous d’abord pour signaler des produits',
    'Log in first to report offers':
        'Connectez-vous d’abord pour signaler des offres',
    'Log in first to report packs':
        'Connectez-vous d’abord pour signaler des packs',
    'Please select a rating': 'Veuillez sélectionner une note',
    'Report submitted. Thank you.': 'Signalement envoyé. Merci.',
    'Failed to send report': 'Échec de l’envoi du signalement',
    'Review deleted successfully': 'Avis supprimé avec succès',
    'Failed to delete review': 'Échec de la suppression de l’avis',
    'You have': 'Vous avez',
    'Search': 'Rechercher',
    'See all': 'Voir tout',
    'No favorite products': 'Aucun produit favori',
    'Add products to your favorites to find them here easily':
        'Ajoutez des produits à vos favoris pour les retrouver ici facilement',
    'Explore Products': 'Explorer les produits',
    'Empty pack': 'Pack vide',
    'An error occurred while loading favorites':
        'Une erreur est survenue lors du chargement des favoris',
    'Packs': 'Packs',
    'Select Wilaya': 'Sélectionner la wilaya',
    'Select Baladiya': 'Sélectionner la baladiya',
    'Adrar': 'Adrar',
    'Chlef': 'Chlef',
    'Laghouat': 'Laghouat',
    'Oum El Bouaghi': 'Oum El Bouaghi',
    'Batna': 'Batna',
    'Béjaïa': 'Béjaïa',
    'Biskra': 'Biskra',
    'Béchar': 'Béchar',
    'Blida': 'Blida',
    'Bouira': 'Bouira',
    'Tamanrasset': 'Tamanrasset',
    'Tébessa': 'Tébessa',
    'Tlemcen': 'Tlemcen',
    'Tiaret': 'Tiaret',
    'Tizi Ouzou': 'Tizi Ouzou',
    'Algiers': 'Alger',
    'Djelfa': 'Djelfa',
    'Jijel': 'Jijel',
    'Sétif': 'Sétif',
    'Saïda': 'Saïda',
    'Skikda': 'Skikda',
    'Sidi Bel Abbès': 'Sidi Bel Abbès',
    'Annaba': 'Annaba',
    'Guelma': 'Guelma',
    'Constantine': 'Constantine',
    'Médéa': 'Médéa',
    'Mostaganem': 'Mostaganem',
    'M\'Sila': 'M\'Sila',
    'Mascara': 'Mascara',
    'Ouargla': 'Ouargla',
    'Oran': 'Oran',
    'El Bayadh': 'El Bayadh',
    'Illizi': 'Illizi',
    'Bordj Bou Arreridj': 'Bordj Bou Arréridj',
    'Boumerdès': 'Boumerdès',
    'El Tarf': 'El Tarf',
    'Tindouf': 'Tindouf',
    'Tissemsilt': 'Tissemsilt',
    'El Oued': 'El Oued',
    'Khenchela': 'Khenchela',
    'Souk Ahras': 'Souk Ahras',
    'Tipaza': 'Tipaza',
    'Mila': 'Mila',
    'Aïn Defla': 'Aïn Defla',
    'Naâma': 'Naâma',
    'Aïn Témouchent': 'Aïn Témouchent',
    'Ghardaïa': 'Ghardaïa',
    'Relizane': 'Relizane',
    'Timimoun': 'Timimoun',
    'Bordj Badji Mokhtar': 'Bordj Badji Mokhtar',
    'Ouled Djellal': 'Ouled Djellal',
    'Béni Abbès': 'Béni Abbès',
    'In Salah': 'In Salah',
    'In Guezzam': 'In Guezzam',
    'Touggourt': 'Touggourt',
    'Djanet': 'Djanet',
    'El M\'Ghair': 'El M\'Ghair',
    'El Meniaa': 'El Meniaa',
    'Search wilaya...': 'Rechercher une wilaya...',
    'Search baladiya...': 'Rechercher une baladiya...',
    'Search wilayas...': 'Rechercher des wilayas...',
    'Search baladiyat...': 'Rechercher des baladiyat...',
    'baladiyat': 'baladiyat',
    'Filter by Location': 'Filtrer par localisation',
    'All Algeria': 'Toute l’Algérie',
    'All Locations': 'Tous les lieux',
    'areas': 'zones',
    'in': 'dans',
    'Apply - All Algeria': 'Appliquer - Toute l’Algérie',
    'Apply - All Locations': 'Appliquer - Tous les lieux',
    'Apply': 'Appliquer',
    'wilayas': 'wilayas',
    'baladiyat selected': 'baladiyat sélectionnées',
    'All baladiyat in': 'Toutes les baladiyat de',
    'Deselect': 'Désélectionner',
    'Select all': 'Tout sélectionner',
    'Select the wilaya first to choose specific baladiyat':
        'Sélectionnez d’abord la wilaya pour choisir des baladiyat spécifiques',
    'more': 'de plus',
    'Show less': 'Afficher moins',
    'Select areas you deliver to': 'Sélectionnez les zones où vous livrez',
    'Customers can come pick up': 'Les clients peuvent venir récupérer',
    'No areas selected': 'Aucune zone sélectionnée',
    'Add Areas': 'Ajouter des zones',
    'Ready to search': 'Prêt à rechercher',
    'Choose type and categories, then tap Search':
        'Choisissez le type et les catégories, puis appuyez sur Rechercher',
    'Could not get current GPS location':
        'Impossible d’obtenir la position GPS actuelle',
    'Open Location Settings': 'Ouvrir les paramètres de localisation',
    'Open App Settings': 'Ouvrir les paramètres de l’application',
    'Location permission denied': 'Permission de localisation refusée',
    'Failed to get current GPS location':
        'Échec de récupération de la position GPS actuelle',
    'Categories': 'Catégories',
    'Select Category': 'Sélectionner une catégorie',
    'Select category': 'Sélectionner une catégorie',
    'No products found': 'Aucun produit trouvé',
    'Just now': 'À l’instant',
    'minute ago': 'minute plus tôt',
    'minutes ago': 'minutes plus tôt',
    'hour ago': 'heure plus tôt',
    'hours ago': 'heures plus tôt',
    'day ago': 'jour plus tôt',
    'days ago': 'jours plus tôt',
    'week ago': 'semaine plus tôt',
    'weeks ago': 'semaines plus tôt',
    'month ago': 'mois plus tôt',
    'months ago': 'mois plus tôt',
    'Confirm': 'Confirmer',
    'No categories found': 'Aucune catégorie trouvée',
    'Loading categories, please wait...':
        'Chargement des catégories, veuillez patienter...',
    'Loading categories...': 'Chargement des catégories...',
    'No categories available': 'Aucune catégorie disponible',
    'Product Images': 'Images du produit',
    'You can add up to 5 product images':
        'Vous pouvez ajouter jusqu\'à 5 images du produit',
    'Product Name': 'Nom du produit',
    'Enter product name': 'Entrez le nom du produit',
    'Please enter product name': 'Veuillez entrer le nom du produit',
    'Price': 'Prix',
    'Please enter price': 'Veuillez entrer le prix',
    'Add product description..': 'Ajoutez la description du produit..',
    'Show price to customers in listings':
        'Afficher le prix aux clients dans les listes',
    'Is the product available for sale?':
        'Le produit est-il disponible à la vente ?',
    'Publish Product': 'Publier le produit',
    'Add Images': 'Ajouter des images',
    'Tap to upload': 'Touchez pour téléverser',
    'Please add at least one image': 'Veuillez ajouter au moins une image',
    'Please select a category': 'Veuillez sélectionner une catégorie',
    'Failed to delete product': 'Échec de la suppression du produit',
    'Product updated successfully': 'Produit mis à jour avec succès',
    'Product published successfully': 'Produit publié avec succès',
    'Error selecting images': 'Erreur lors de la sélection des images',
    'Set your location area or GPS in Edit Profile before posting.':
        'Définissez votre zone ou votre GPS dans Modifier le profil avant de publier.',
    'update': 'mettre à jour',
    'publish': 'publier',
    'product': 'produit',
    'This product already exists in the pack':
        'Ce produit existe déjà dans le pack',
    'Select pack products first': 'Sélectionnez d\'abord les produits du pack',
    'Enter pack name': 'Entrez le nom du pack',
    'Enter pack sale price': 'Entrez le prix de vente du pack',
    'Pack price must be less than the total price of products':
        'Le prix du pack doit être inférieur au prix total des produits',
    'Must login first': 'Vous devez vous connecter d\'abord',
    'No store found for this user': 'Aucun magasin trouvé pour cet utilisateur',
    'Pack updated successfully': 'Pack mis à jour avec succès',
    'Pack published successfully': 'Pack publié avec succès',
    'Error during publishing': 'Erreur lors de la publication',
    'You haven\'t added any products to the pack yet':
        'Vous n\'avez encore ajouté aucun produit au pack',
    'Use the search above to add products':
        'Utilisez la recherche ci-dessus pour ajouter des produits',
    'Pack Name *': 'Nom du pack *',
    'Pack Sale Price': 'Prix de vente du pack',
    'Delivery areas': 'Zones de livraison',
    'Select delivery areas (optional)':
        'Sélectionner les zones de livraison (optionnel)',
    'No areas selected — your store address will be used by default':
        'Aucune zone sélectionnée — l\'adresse de votre magasin sera utilisée par défaut',
    'Publish Pack': 'Publier le pack',
    'km radius': 'km de rayon',
    'Filters': 'Filtres',
    'Reset': 'Réinitialiser',
    'Sort By': 'Trier par',
    'Price Range': 'Fourchette de prix',
    'Minimum Rating': 'Note minimale',
    'Apply Filters': 'Appliquer les filtres',
    'Results': 'Résultats',
    'No Results Found': 'Aucun résultat trouvé',
    'Try adjusting your search or filters to find what you\'re looking for':
        'Essayez d’ajuster votre recherche ou vos filtres pour trouver ce que vous cherchez',
    'Clear Filters': 'Effacer les filtres',
    'Customers can call you': 'Les clients peuvent vous appeler',
    'Call button will be hidden': 'Le bouton d’appel sera masqué',
    'Customers can contact you': 'Les clients peuvent vous contacter',
    'Buttons will be hidden': 'Les boutons seront masqués',
    'Tap to select location': 'Appuyez pour sélectionner l’emplacement',
    'Important: Nearby filter needs GPS coordinates. If GPS is not set, your products will not appear in distance search. Also, area search (Wilaya/Baladiya) depends on your address. If address is empty, your products will not appear in area filter.':
        'Important : le filtre à proximité nécessite des coordonnées GPS. Si le GPS n’est pas défini, vos produits n’apparaîtront pas dans la recherche par distance. La recherche par zone (Wilaya/Baladiya) dépend aussi de votre adresse. Si l’adresse est vide, vos produits n’apparaîtront pas dans le filtre de zone.',
    'GPS coordinates selected': 'Coordonnées GPS sélectionnées',
    'GPS coordinates not selected yet':
        'Coordonnées GPS pas encore sélectionnées',
    'Nearby search visibility': 'Visibilité dans la recherche à proximité',
    'Nearby results use your GPS. Turn this on to show your store by distance. You can turn it off anytime.':
        'Les résultats à proximité utilisent votre GPS. Activez ceci pour afficher votre magasin par distance. Vous pouvez le désactiver à tout moment.',
    'Store location': 'Emplacement du magasin',
    'Store location (optional)': 'Emplacement du magasin (optionnel)',
    'Select wilaya and baladiya': 'Sélectionnez la wilaya et la baladiya',
    'Select wilaya and baladiya (optional)':
        'Sélectionnez la wilaya et la baladiya (optionnel)',
    'Please choose wilaya and baladiya':
        'Veuillez choisir la wilaya et la baladiya',
    'People searching in that baladiya will see your posts unless you enable delivery.':
        'Les personnes qui recherchent dans cette baladiya verront vos publications, sauf si vous activez la livraison.',
    'Choose the wilaya and baladiya where your store is based. If you do not support delivery, your posts will mainly appear to people searching in that baladiya.':
        'Choisissez la wilaya et la baladiya où se situe votre magasin. Si vous ne proposez pas la livraison, vos publications apparaîtront surtout aux personnes qui recherchent dans cette baladiya.',
    'You can skip this step for now. Add your wilaya and baladiya later if you want better local search visibility.':
        'Vous pouvez ignorer cette étape pour le moment. Ajoutez votre wilaya et votre baladiya plus tard si vous voulez une meilleure visibilité dans la recherche locale.',
    'Location is optional. If you add it, your posts can appear more accurately to people searching in that wilaya or baladiya.':
        'L’emplacement est facultatif. Si vous l’ajoutez, vos publications peuvent apparaître plus précisément aux personnes qui recherchent dans cette wilaya ou cette baladiya.',
    'Show my store in nearby results':
        'Afficher mon magasin dans les résultats à proximité',
    'Visible in nearby results': 'Visible dans les résultats à proximité',
    'Hidden from nearby results': 'Masqué des résultats à proximité',
    'GPS location is saved': 'La position GPS est enregistrée',
    'Set GPS location': 'Définir la position GPS',
    'Location updated successfully ✅': 'Position mise à jour avec succès ✅',
    'Could not get location': 'Impossible d’obtenir la position',
    '✅ Profile saved successfully': '✅ Profil enregistré avec succès',
    'Edit Product': 'Modifier le produit',
    'Publish New Product': 'Publier un nouveau produit',
    'Name': 'Nom',
    'Description': 'Description',
    'Enter your name': 'Entrez votre nom',
    'Describe your store...': 'Décrivez votre magasin...',
    'Newest': 'Plus récent',
    'Oldest': 'Plus ancien',
    'Highest Rated': 'Mieux noté',
    'Lowest Price': 'Prix le plus bas',
    'Highest Price': 'Prix le plus élevé',
    'Top Rated': 'Top noté',
    'Loading usage status...': 'Chargement de l’etat d’utilisation...',
    'Your current usage is unavailable right now.':
        'Votre utilisation actuelle est indisponible pour le moment.',
    'Each screen answers one clear question.':
        'Chaque ecran repond a une question claire.',
    'Hide plans': 'Masquer les plans',
    'Show more plans': 'Afficher plus de plans',
    'No plans available right now':
        'Aucun plan n’est disponible pour le moment',
    'Please refresh in a moment to load the subscription catalog.':
        'Veuillez actualiser dans un instant pour charger le catalogue des abonnements.',
    'of': 'sur',
    'products used': 'produits utilises',
    'Most Popular': 'Le plus populaire',
    'Featured exposure and core promotion tools.':
        'Mise en avant et outils de promotion essentiels.',
    'Higher visibility in recommendations.':
        'Visibilite plus forte dans les recommandations.',
    'DZD / month': 'DZD / mois',
    'Up to': 'Jusqu’a',
    'Duration': 'Duree',
    'day': 'jour',
    'days': 'jours',
    'Ad Impr': 'Impr pub',
    'Start now': 'Commencer maintenant',
    '7 days free': '7 jours gratuits',
    'Could not select images': 'Impossible de selectionner les images',
    'Please upload at least one receipt image':
        'Veuillez televerser au moins une image du recu',
    'Request number': 'Numero de demande',
    'Number copied': 'Numero copie',
    'Plan information': 'Informations du plan',
    'Account number (RIB)': 'Numero de compte (RIB)',
    'No need to type the number or take a screenshot.':
        'Pas besoin de saisir le numero ni de faire une capture d’ecran.',
    'Open your banking app and start a transfer.':
        'Ouvrez votre application bancaire et commencez un virement.',
    'Send the amount to this account.': 'Envoyez le montant vers ce compte.',
    'Upload the receipt in the next step.':
        'Televersez le recu a l’etape suivante.',
    'Upload receipt image': 'Televerser l’image du recu',
    'Tap to choose an image': 'Touchez pour choisir une image',
    'Camera or gallery': 'Camera ou galerie',
    'Locating...': 'Localisation...',
    'Today': 'Aujourd’hui',
    'Favorites': 'Favoris',
    'Stay': 'Temps passe',
    'Store': 'Magasin',
    'Follows (Ad)': 'Abonnes (pub)',
    'Advertising': 'Publicite en cours',
    'What these numbers mean': 'Ce que signifient ces chiffres',
    'You have no active ads right now. Start with one clear product or pack.':
        'Vous n’avez aucune annonce active pour le moment. Commencez par un produit ou un pack clair.',
    'Your ads are active, but they still need reach. Review dates, placement, and budget.':
        'Vos annonces sont actives, mais elles manquent encore de portee. Revoyez les dates, l’emplacement et le budget.',
    'People are seeing your ads, but clicks are still low. Improve the image, title, or offer.':
        'Les gens voient vos annonces, mais les clics restent faibles. Ameliorez l’image, le titre ou l’offre.',
    'Your ads are getting both views and clicks. Keep budget on the products that move fastest.':
        'Vos annonces obtiennent des vues et des clics. Gardez le budget sur les produits qui avancent le plus vite.',
    'Nearby performance improves when both your store GPS and address are complete.':
        'Les performances a proximite s’ameliorent lorsque le GPS et l’adresse du magasin sont complets.',
    'Change the dates or create a new ad to start collecting results.':
        'Changez les dates ou creez une nouvelle annonce pour commencer a collecter des resultats.',
    'Campaign': 'Campagne',
    'AD': 'PUB',
    'Unique': 'Uniques',
    'Hour': 'Heure',
    'Remaining': 'Restant',
    'No product performance data for this period.':
        'Aucune donnee de performance produit pour cette periode.',
    'Once ads collect views and clicks, product-level insights will appear here.':
        'Quand les annonces accumuleront des vues et des clics, des informations par produit apparaitront ici.',
    'Failed to open ad editor': 'Impossible d’ouvrir l’editeur d’annonce',
    'Tips': 'Conseils',
    'Choose high-demand products, reserve impression budget for fast movers, and keep the home-top placement for your most visual campaigns.':
        'Choisissez des produits a forte demande, gardez le budget d’impression pour les articles qui bougent vite, et reservez la position haute de l’accueil a vos campagnes les plus visuelles.',
    'Preset': 'Preset',
    'All dates': 'Toutes les dates',
    'Custom': 'Personnalise',
    'Select Pack to Advertise': 'Selectionner un pack a promouvoir',
    'Already has an active ad': 'Possede deja une annonce active',
    'Ready for advertising': 'Pret pour la publicite',
    'Advertise': 'Promouvoir',
    'Search products…': 'Rechercher des produits...',
    'Product Performance': 'Performance produit',
    'العربية': 'Arabe',
  };

  static const Map<String, String> _ar = {
    'Add Product': 'إضافة منتج',
    'Add Discount': 'إضافة تخفيض',
    'Add Pack': 'إضافة باك',
    'Ads': 'الإعلانات',
    'All': 'الكل',
    'Available': 'متاح',
    'Back': 'رجوع',
    'Back to home': 'العودة للرئيسية',
    'Birthday': 'تاريخ الميلاد',
    'Buy': 'شراء',
    'Call': 'اتصال',
    'Camera': 'الكاميرا',
    'Cancel': 'إلغاء',
    'Choose image source': 'اختر مصدر الصورة',
    'City': 'المدينة',
    'Clear': 'مسح',
    'Close': 'إغلاق',
    'Coin Payment': 'دفع العملات',
    'Coin Store': 'متجر العملات',
    'Coins': 'عملات',
    'coins': 'عملة',
    'You need': 'تحتاج',
    'Balance': 'الرصيد',
    'Missing': 'الناقص',
    'DZD': 'دج',
    'km': 'كم',
    'Coordinates Locked': 'الإحداثيات مقفلة',
    'Complete Your Profile': 'أكمل ملفك الشخصي',
    'Name, birthday, gender and categories':
        'الاسم وتاريخ الميلاد والجنس والفئات',
    'Male': 'ذكر',
    'Female': 'أنثى',
    'Select categories': 'اختر الفئات',
    'selected': 'محدد',
    'Copy link': 'نسخ الرابط',
    'Copy number': 'نسخ الرقم',
    'Create New Pack': 'إنشاء باك جديد',
    'Create Sponsored Ad': 'إنشاء إعلان ممول',
    'Edit Sponsored Ad': 'تعديل الإعلان الممول',
    'Edit Discount': 'تعديل التخفيض',
    'Select Pack to Sponsor': 'اختر الباك للإعلان الممول',
    'Select Discount to Sponsor': 'اختر التخفيض للإعلان الممول',
    'Tap to select product...': 'اضغط لاختيار منتج...',
    'Tap to select pack to sponsor...': 'اضغط لاختيار باك للإعلان الممول...',
    'Tap to select a product with active discount...':
        'اضغط لاختيار منتج لديه تخفيض نشط...',
    'Tap to select product to sponsor...':
        'اضغط لاختيار المنتج المراد ترويجه...',
    'Ad Active': 'الإعلان نشط',
    'Show this sponsored ad to customers': 'اعرض هذا الإعلان الممول للزبائن',
    'Show this discount to customers': 'اعرض هذا التخفيض للزبائن',
    'Saving...': 'جارٍ الحفظ...',
    'Save Changes': 'حفظ التغييرات',
    'Launch Sponsored Ad': 'إطلاق الإعلان الممول',
    'Apply Discount': 'تطبيق التخفيض',
    'Delete Sponsored Ad?': 'حذف الإعلان الممول؟',
    'Delete Discount?': 'حذف التخفيض؟',
    'This will remove the sponsored ad from this product.':
        'سيؤدي هذا إلى إزالة الإعلان الممول من هذا المنتج.',
    'This will remove the discount from this product.':
        'سيؤدي هذا إلى إزالة التخفيض من هذا المنتج.',
    'Sponsored ad deleted successfully': 'تم حذف الإعلان الممول بنجاح',
    'Discount deleted successfully': 'تم حذف التخفيض بنجاح',
    'Failed to delete sponsored ad': 'فشل حذف الإعلان الممول',
    'Failed to delete discount': 'فشل حذف التخفيض',
    'Sponsored ad updated successfully': 'تم تحديث الإعلان الممول بنجاح',
    'Discount edited successfully': 'تم تعديل التخفيض بنجاح',
    'Sponsored ad created successfully': 'تم إنشاء الإعلان الممول بنجاح',
    'Sponsored': 'ممَوَّل',
    'View deal': 'عرض العرض',
    'Discount added successfully': 'تمت إضافة التخفيض بنجاح',
    'No active discounts found. Create a discount first.':
        'لا توجد تخفيضات نشطة. أنشئ تخفيضًا أولًا.',
    'Please enter the number of ad impressions':
        'يرجى إدخال عدد مرات ظهور الإعلان',
    'Insufficient Ad View Coins. Need \$extraNeeded more impressions budget, available \$affordable.':
        'عملات مشاهدات الإعلان غير كافية. تحتاج إلى \$extraNeeded من ميزانية الظهور، المتاح \$affordable.',
    'am': 'ص',
    'pm': 'م',
    'No hour selected': 'لم يتم اختيار أي ساعة',
    'All day': 'كل اليوم',
    'Business hours': 'ساعات العمل',
    'All day (24h)': 'كل اليوم (24 ساعة)',
    'Business hours (8AM-7PM)': 'ساعات العمل (8ص-7م)',
    'Select at least one hour': 'اختر ساعة واحدة على الأقل',
    'Existing Sponsored Ad': 'إعلان ممول موجود',
    'Existing Discount': 'تخفيض موجود',
    'This product already has an ad campaign. Do you want to edit it?':
        'هذا المنتج لديه حملة إعلانية بالفعل. هل تريد تعديلها؟',
    'This product already has a discount. Do you want to edit it?':
        'هذا المنتج لديه تخفيض بالفعل. هل تريد تعديله؟',
    'Start Date & Time': 'تاريخ ووقت البداية',
    'End Date & Time': 'تاريخ ووقت النهاية',
    'Please select a pack': 'يرجى اختيار باك',
    'Please select a product': 'يرجى اختيار منتج',
    'Age range is invalid': 'نطاق العمر غير صالح',
    'Select at least one hour to show your ad':
        'اختر ساعة واحدة على الأقل لعرض إعلانك',
    'Discount target requires a product with active discount.':
        'استهداف التخفيض يتطلب منتجًا بتخفيض نشط.',
    'Select at least one target wilaya': 'اختر ولاية مستهدفة واحدة على الأقل',
    'Choose target radius in km': 'اختر نصف القطر المستهدف بالكيلومتر',
    'End time must be after start time':
        'يجب أن يكون وقت النهاية بعد وقت البداية',
    'Duration exceeds the current limit (\$maxDays days).':
        'المدة تتجاوز الحد الحالي (\$maxDays يومًا).',
    'Failed to': 'فشل في',
    'save': 'الحفظ',
    'create': 'الإنشاء',
    'sponsored ad': 'الإعلان الممول',
    'discount': 'التخفيض',
    'This discount is not available': 'هذا التخفيض غير متاح',
    'Sponsored Pack Summary': 'ملخص الباك الممول',
    'Sponsored Discount Summary': 'ملخص التخفيض الممول',
    'Sponsored Product Summary': 'ملخص المنتج الممول',
    'Current Price': 'السعر الحالي',
    'Discount Percentage (%)': 'نسبة التخفيض (%)',
    'Required': 'مطلوب',
    'Invalid': 'غير صالح',
    'Ad Impressions': 'مرات ظهور الإعلان',
    'e.g. 5000': 'مثال: 5000',
    'Current ad impressions to activate:': 'مرات الظهور الحالية للتفعيل:',
    'Age From': 'العمر من',
    'Age To': 'العمر إلى',
    'Choose Radius (km)': 'اختر نصف القطر (كم)',
    'Sponsored ad will stay active until impressions are exhausted.':
        'سيبقى الإعلان الممول نشطًا حتى تنفد مرات الظهور.',
    'Select Product to Sponsor': 'اختر المنتج للإعلان الممول',
    'Select products to sponsor': 'اختر منتجات للإعلان الممول',
    'Select Product': 'اختر المنتج',
    'Select Target Wilayas': 'اختر الولايات المستهدفة',
    'wilayas selected': 'ولايات محددة',
    'Current Plan': 'الخطة الحالية',
    'Delete': 'حذف',
    'Delete Product?': 'حذف المنتج؟',
    'Delete cover image?': 'حذف صورة الغلاف؟',
    'Delete profile image?': 'حذف صورة الملف الشخصي؟',
    'Delivery Available': 'التوصيل متاح',
    'Discount': 'تخفيض',
    'Discounts': 'تخفيضات',
    'Discover Plans': 'اكتشاف الخطط',
    'Edit': 'تعديل',
    'Edit Ad': 'تعديل الإعلان',
    'Edit Information': 'تعديل المعلومات',
    'Edit Profile': 'تعديل الملف الشخصي',
    'Failed to load dashboard': 'تعذر تحميل لوحة التحكم',
    'Failed to load plans': 'تعذر تحميل الخطط',
    'Enable home delivery for this pack': 'تفعيل التوصيل المنزلي لهذا الباك',
    'English': 'الإنجليزية',
    'Enter your full name': 'أدخل اسمك الكامل',
    'Favorite Categories': 'الفئات المفضلة',
    'Featured Packs': 'باقات مميزة',
    'Featured Stores': 'متاجر مميزة',
    'Follow': 'متابعة',
    'Follow a store to see it here': 'تابع متجراً ليظهر هنا',
    'Following': 'تتم المتابعة',
    'Français': 'الفرنسية',
    'Full Name': 'الاسم الكامل',
    'Gallery': 'المعرض',
    'Gender': 'الجنس',
    'Home': 'الرئيسية',
    'Latest Products': 'أحدث المنتجات',
    'Load more': 'عرض المزيد',
    'Location': 'الموقع',
    'Select your location': 'اختر موقعك',
    'Tap to change': 'اضغط للتغيير',
    'Tap to choose location': 'اضغط لاختيار الموقع',
    'Logout': 'تسجيل الخروج',
    'Mark all as read': 'تحديد الكل كمقروء',
    'New Price:': 'السعر الجديد:',
    'New Price': 'السعر الجديد',
    'Schedule': 'الجدولة',
    'Tap to select date': 'اضغط لاختيار التاريخ',
    'at': 'على',
    'New Product': 'منتج جديد',
    'No ads found in this period.': 'لم يتم العثور على إعلانات في هذه الفترة.',
    'No baladiya found': 'لم يتم العثور على بلدية',
    'No content here yet': 'لا يوجد محتوى هنا بعد',
    'No followed stores': 'لا توجد متاجر متابعة',
    'No manual follow-up needed': 'لا حاجة لمتابعة يدوية',
    'No notifications': 'لا توجد إشعارات',
    'No notifications yet': 'لا توجد إشعارات بعد',
    'No packs available for advertising.': 'لا توجد باقات متاحة للإعلانات.',
    'No packs available yet.': 'لا توجد باقات متاحة بعد.',
    'No purchase requests yet.': 'لا توجد طلبات شراء بعد.',
    'No transactions yet.': 'لا توجد معاملات بعد.',
    'No wilaya found': 'لم يتم العثور على ولاية',
    'Note (optional)': 'ملاحظة (اختياري)',
    'Nearby': 'بالقرب',
    'new notifications': 'إشعارات جديدة',
    'Notifications': 'الإشعارات',
    'Notification': 'إشعار',
    'Notifications coming soon': 'الإشعارات قريباً',
    'Filters coming soon': 'الفلاتر قريباً',
    'New User Offer': 'عرض مستخدم جديد',
    'OK': 'موافق',
    'Open Settings': 'فتح الإعدادات',
    'Original Price:': 'السعر الأصلي:',
    'Pack': 'باك',
    'Pack Details': 'تفاصيل الباك',
    'Payment': 'الدفع',
    'Registration failed': 'فشل التسجيل',
    'Payment note (optional)': 'ملاحظة الدفع (اختياري)',
    'Payment proof images': 'صور إثبات الدفع',
    'Please select wilaya and baladiya': 'يرجى اختيار الولاية والبلدية',
    'Product': 'منتج',
    'Product Details': 'تفاصيل المنتج',
    'Products': 'المنتجات',
    'Posts': 'المنشورات',
    'Followers': 'المتابعون',
    'Rating': 'التقييم',
    'Contact Store': 'التواصل مع المتجر',
    'Add Favorite': 'إضافة إلى المفضلة',
    'Remove Favorite': 'إزالة من المفضلة',
    'Added to favorites': 'تمت الإضافة إلى المفضلة',
    'Cover image updated successfully': 'تم تحديث صورة الغلاف بنجاح',
    'Failed to update cover image': 'فشل تحديث صورة الغلاف',
    'Cover image deleted successfully': 'تم حذف صورة الغلاف بنجاح',
    'Failed to delete cover image': 'فشل حذف صورة الغلاف',
    'Profile image updated successfully': 'تم تحديث صورة الملف الشخصي بنجاح',
    'Failed to update image': 'فشل تحديث الصورة',
    'Profile image deleted successfully': 'تم حذف صورة الملف الشخصي بنجاح',
    'Failed to delete profile image': 'فشل حذف صورة الملف الشخصي',
    'Logged out successfully!': 'تم تسجيل الخروج بنجاح!',
    'Log in to follow stores': 'سجل الدخول لمتابعة المتاجر',
    'Followed store': 'تمت متابعة المتجر',
    'Unfollowed store': 'تم إلغاء متابعة المتجر',
    'Failed to update follow': 'فشل تحديث المتابعة',
    'Rate this store': 'قيّم هذا المتجر',
    'Write Review': 'اكتب تقييماً',
    'Removed from favorites': 'تمت الإزالة من المفضلة',
    'Failed to update favorite': 'تعذر تحديث المفضلة',
    'Failed to update favorites': 'تعذر تحديث المفضلات',
    'Log in to save favorites': 'سجل الدخول لحفظ المفضلة',
    'Products with Discounts': 'منتجات بتخفيضات',
    'Top Discounts': 'أفضل التخفيضات',
    'Top Products': 'أفضل المنتجات',
    'Top Packs': 'أفضل الباقات',
    'Product link copied': 'تم نسخ رابط المنتج',
    'Review submitted successfully': 'تم إرسال التقييم بنجاح',
    'Failed to submit review': 'فشل إرسال التقييم',
    'Please upload at least one payment proof.':
        'يرجى رفع إثبات دفع واحد على الأقل.',
    'Payment request': 'طلب الدفع',
    'is pending server approval.': 'قيد انتظار موافقة الخادم.',
    'Coins are added after approval.': 'تتم إضافة العملات بعد الموافقة.',
    'Removed pack products from favorites':
        'تمت إزالة منتجات الباقة من المفضلة',
    'Added pack products to favorites': 'تمت إضافة منتجات الباقة إلى المفضلة',
    'An error occurred': 'حدث خطأ',
    'No image selected': 'لم يتم اختيار صورة',
    'Profile picture updated successfully': 'تم تحديث صورة الملف بنجاح',
    'Failed to delete image': 'فشل حذف الصورة',
    'Please fill in all required fields': 'يرجى ملء جميع الحقول المطلوبة',
    'Data saved successfully': 'تم حفظ البيانات بنجاح',
    'Error saving data': 'خطأ أثناء حفظ البيانات',
    'Failed to update cover': 'فشل تحديث الغلاف',
    'Failed to delete cover': 'فشل حذف الغلاف',
    'Please enter your name': 'يرجى إدخال اسمك',
    'Profile': 'الملف الشخصي',
    'Promotion Details': 'تفاصيل العرض',
    'Quantity': 'الكمية',
    'Rating: ': 'التقييم: ',
    'Regular Price:': 'السعر العادي:',
    'Regular Total:': 'المجموع العادي:',
    'Report Store': 'الإبلاغ عن المتجر',
    'Report Offer': 'الإبلاغ عن العرض',
    'Report Pack': 'الإبلاغ عن الباك',
    'Report': 'إبلاغ',
    'Report Product': 'الإبلاغ عن المنتج',
    'Duplicate / spam listing': 'إعلان مكرر / مزعج',
    'Duplicate / spam store': 'متجر مكرر / مزعج',
    'Fake / counterfeit product': 'منتج مزيف / مقلد',
    'Fake store / no real location': 'متجر وهمي / بدون موقع حقيقي',
    'Scam / asked for prepayment': 'احتيال / طلب دفع مسبق',
    'Offensive / prohibited content': 'محتوى مسيء / محظور',
    'Other (price mismatch, wrong info)': 'أخرى (سعر غير مطابق، معلومات خاطئة)',
    'Other (wrong info, bad service)': 'أخرى (معلومات خاطئة، خدمة سيئة)',
    'Recommended for you': 'موصى به لك',
    'Request received': 'تم استلام الطلب',
    'Request submitted': 'تم إرسال الطلب',
    'Save': 'حفظ',
    'Saved': 'المحفوظات',
    'Save Failed': 'فشل الحفظ',
    'Savings': 'التوفير',
    'Search categories...': 'ابحث عن الفئات...',
    'Search my posts...': 'ابحث في منشوراتي...',
    'Search packs...': 'ابحث عن الباقات...',
    'Search products, stores...': 'ابحث عن المنتجات والمتاجر...',
    'Search products...': 'ابحث عن المنتجات...',
    'Search Radius': 'نطاق البحث',
    'Your Coins': 'عملاتك',
    'Publishing Costs': 'تكاليف النشر',
    'Product Post': 'نشر منتج',
    'Pack Post': 'نشر باك',
    'Promotion Post': 'نشر عرض',
    'Purchase Requests': 'طلبات الشراء',
    'Recent Transactions': 'آخر المعاملات',
    'coin': 'عملة',
    'Impressions': 'مرات الظهور',
    'Clicks': 'النقرات',
    'Active Ads': 'الإعلانات النشطة',
    'Advertised': 'ممول',
    'Views': 'المشاهدات',
    '14D': '14ي',
    'Ad View Coins balance:': 'رصيد عملات مشاهدات الإعلان:',
    'Ad View:': 'مشاهدة إعلان:',
    'ad View:': 'مشاهدة إعلان:',
    'ad view': 'مشاهدة إعلان',
    'Cost per impression:': 'تكلفة كل ظهور:',
    'Current max impressions you can activate:':
        'أقصى عدد ظهور يمكنك تفعيله الآن:',
    'Selected hours': 'الساعات المحددة',
    'Product Create': 'إنشاء منتج',
    'product create': 'إنشاء منتج',
    'See All': 'عرض الكل',
    'View All': 'عرض الكل',
    'Select Hours': 'اختر الساعات',
    'Select product to add...': 'اختر المنتج لإضافته...',
    'Add details (optional)': 'أضف تفاصيل (اختياري)',
    'Send Report': 'إرسال البلاغ',
    'Send Product': 'إرسال المنتج',
    'Send request': 'إرسال الطلب',
    'Share': 'مشاركة',
    'Share Product': 'مشاركة المنتج',
    'Share Store': 'مشاركة المتجر',
    'Show At Hour': 'عرض عند الساعة',
    'Show Price': 'عرض السعر',
    'Show Product QR': 'عرض QR المنتج',
    'Show WhatsApp/social buttons': 'عرض أزرار واتساب/التواصل',
    'Show call button': 'عرض زر الاتصال',
    'Show more': 'عرض المزيد',
    'Show this pack to customers in your store': 'اعرض هذا الباك لعملائك',
    'Social Accounts': 'الحسابات الاجتماعية',
    'Store Location': 'موقع المتجر',
    'Stores': 'المتاجر',
    'Submit Review': 'إرسال التقييم',
    'Reviews': 'التقييمات',
    'Your Review': 'تقييمك',
    'Submit payment request': 'إرسال طلب الدفع',
    'This action cannot be undone.': 'لا يمكن التراجع عن هذا الإجراء.',
    'Delete your review?': 'حذف تقييمك؟',
    'This will permanently remove your review.':
        'سيؤدي هذا إلى حذف تقييمك نهائيًا.',
    'This item is no longer available.': 'هذا العنصر لم يعد متاحًا.',
    'This will remove your current cover image.':
        'سيؤدي هذا إلى إزالة صورة الغلاف الحالية.',
    'This will remove your current profile image.':
        'سيؤدي هذا إلى إزالة صورة الملف الشخصي الحالية.',
    'Total': 'المجموع',
    'Total Product Prices:': 'إجمالي أسعار المنتجات:',
    'Transfer reference / notes': 'مرجع التحويل / ملاحظات',
    'Upload 1 to 3 images. Your request will be reviewed by admin.':
        'قم برفع من 1 إلى 3 صور. سيتم مراجعة طلبك من طرف المشرف.',
    'Verified': 'موثّق',
    'Verify Code': 'تحقق من الرمز',
    'Verify': 'تحقق',
    'Sign in with phone number': 'تسجيل الدخول برقم الهاتف',
    'Sign In With Phone': 'تسجيل الدخول بالهاتف',
    'Enter your Algerian number (0XXXXXXXXX)':
        'أدخل رقمك الجزائري (0XXXXXXXXX)',
    'Phone Number': 'رقم الهاتف',
    'Please enter your phone number': 'يرجى إدخال رقم هاتفك',
    'Use format 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX':
        'استخدم الصيغة 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX',
    'Send Code': 'إرسال الرمز',
    'Failed to send verification code.': 'فشل في إرسال رمز التحقق.',
    'Server connection failed. Please try again.':
        'فشل الاتصال بالخادم. يرجى المحاولة مرة أخرى.',
    'Enter the 6-digit code': 'أدخل الرمز المكون من 6 أرقام',
    'OTP verification failed.': 'فشل التحقق من رمز OTP.',
    'Verification code resent': 'تمت إعادة إرسال رمز التحقق',
    'Failed to resend code': 'فشل في إعادة إرسال الرمز',
    'We sent a 6-digit code to': 'لقد أرسلنا رمزًا من 6 أرقام إلى',
    'Resend in': 'إعادة الإرسال خلال',
    'Resend code': 'إعادة إرسال الرمز',
    'Skip (Prototype)': 'تخطي (نسخة تجريبية)',
    'Your current location': 'موقعك الحالي',
    'Algeria': 'الجزائر',
    'Session expired. Please login again.':
        'انتهت الجلسة. يرجى تسجيل الدخول مرة أخرى.',
    'No internet connection or server is unreachable':
        'لا يوجد اتصال بالإنترنت أو الخادم غير متاح',
    'Connection timed out. Please try again.':
        'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى.',
    'Server error. Please try again later.':
        'خطأ في الخادم. يرجى المحاولة لاحقًا.',
    'Invalid response format from server': 'تنسيق استجابة الخادم غير صالح',
    'Request failed': 'فشل الطلب',
    'We are reviewing your image...': 'نحن نراجع صورتك...',
    'WhatsApp': 'واتساب',
    'Write your review...': 'اكتب تقييمك...',
    'Log in to add a review': 'سجّل الدخول لإضافة تقييم',
    'Log in first to report products': 'سجّل الدخول أولاً للإبلاغ عن المنتجات',
    'Log in first to report offers': 'سجّل الدخول أولاً للإبلاغ عن العروض',
    'Log in first to report packs': 'سجّل الدخول أولاً للإبلاغ عن الباقات',
    'Please select a rating': 'يرجى اختيار تقييم',
    'Report submitted. Thank you.': 'تم إرسال البلاغ. شكرًا لك.',
    'Failed to send report': 'فشل إرسال البلاغ',
    'Review deleted successfully': 'تم حذف التقييم بنجاح',
    'Failed to delete review': 'فشل حذف التقييم',
    'You have': 'لديك',
    'Search': 'بحث',
    'See all': 'عرض الكل',
    'No favorite products': 'لا توجد منتجات مفضلة',
    'Add products to your favorites to find them here easily':
        'أضف منتجات إلى المفضلة لتجدها هنا بسهولة',
    'Explore Products': 'استكشاف المنتجات',
    'Empty pack': 'باقة فارغة',
    'An error occurred while loading favorites': 'حدث خطأ أثناء تحميل المفضلة',
    'Packs': 'الباقات',
    'Select Wilaya': 'اختر الولاية',
    'Select Baladiya': 'اختر البلدية',
    'Adrar': 'أدرار',
    'Chlef': 'الشلف',
    'Laghouat': 'الأغواط',
    'Oum El Bouaghi': 'أم البواقي',
    'Batna': 'باتنة',
    'Béjaïa': 'بجاية',
    'Biskra': 'بسكرة',
    'Béchar': 'بشار',
    'Blida': 'البليدة',
    'Bouira': 'البويرة',
    'Tamanrasset': 'تمنراست',
    'Tébessa': 'تبسة',
    'Tlemcen': 'تلمسان',
    'Tiaret': 'تيارت',
    'Tizi Ouzou': 'تيزي وزو',
    'Algiers': 'الجزائر',
    'Djelfa': 'الجلفة',
    'Jijel': 'جيجل',
    'Sétif': 'سطيف',
    'Saïda': 'سعيدة',
    'Skikda': 'سكيكدة',
    'Sidi Bel Abbès': 'سيدي بلعباس',
    'Annaba': 'عنابة',
    'Guelma': 'قالمة',
    'Constantine': 'قسنطينة',
    'Médéa': 'المدية',
    'Mostaganem': 'مستغانم',
    'M\'Sila': 'المسيلة',
    'Mascara': 'معسكر',
    'Ouargla': 'ورقلة',
    'Oran': 'وهران',
    'El Bayadh': 'البيض',
    'Illizi': 'إليزي',
    'Bordj Bou Arreridj': 'برج بوعريريج',
    'Boumerdès': 'بومرداس',
    'El Tarf': 'الطارف',
    'Tindouf': 'تندوف',
    'Tissemsilt': 'تيسمسيلت',
    'El Oued': 'الوادي',
    'Khenchela': 'خنشلة',
    'Souk Ahras': 'سوق أهراس',
    'Tipaza': 'تيبازة',
    'Mila': 'ميلة',
    'Aïn Defla': 'عين الدفلى',
    'Naâma': 'النعامة',
    'Aïn Témouchent': 'عين تموشنت',
    'Ghardaïa': 'غرداية',
    'Relizane': 'غليزان',
    'Timimoun': 'تيميمون',
    'Bordj Badji Mokhtar': 'برج باجي مختار',
    'Ouled Djellal': 'أولاد جلال',
    'Béni Abbès': 'بني عباس',
    'In Salah': 'عين صالح',
    'In Guezzam': 'عين قزام',
    'Touggourt': 'تقرت',
    'Djanet': 'جانت',
    'El M\'Ghair': 'المغير',
    'El Meniaa': 'المنيعة',
    'Search wilaya...': 'ابحث عن ولاية...',
    'Search baladiya...': 'ابحث عن بلدية...',
    'Search wilayas...': 'ابحث عن الولايات...',
    'Search baladiyat...': 'ابحث عن البلديات...',
    'baladiyat': 'بلديات',
    'Filter by Location': 'تصفية حسب الموقع',
    'All Algeria': 'كل الجزائر',
    'All Locations': 'كل المواقع',
    'areas': 'مناطق',
    'in': 'في',
    'Apply - All Algeria': 'تطبيق - كل الجزائر',
    'Apply - All Locations': 'تطبيق - كل المواقع',
    'Apply': 'تطبيق',
    'wilayas': 'ولايات',
    'baladiyat selected': 'بلديات محددة',
    'All baladiyat in': 'كل بلديات',
    'Deselect': 'إلغاء التحديد',
    'Select all': 'تحديد الكل',
    'Select the wilaya first to choose specific baladiyat':
        'اختر الولاية أولاً لتحديد بلديات معيّنة',
    'more': 'أكثر',
    'Show less': 'عرض أقل',
    'Select areas you deliver to': 'اختر المناطق التي توصل إليها',
    'Customers can come pick up': 'يمكن للزبائن القدوم للاستلام',
    'No areas selected': 'لم يتم اختيار مناطق',
    'Add Areas': 'إضافة مناطق',
    'Ready to search': 'جاهز للبحث',
    'Choose type and categories, then tap Search':
        'اختر النوع والفئات ثم اضغط بحث',
    'Could not get current GPS location': 'تعذر الحصول على موقع GPS الحالي',
    'Open Location Settings': 'فتح إعدادات الموقع',
    'Open App Settings': 'فتح إعدادات التطبيق',
    'Location permission denied': 'تم رفض إذن الموقع',
    'Failed to get current GPS location': 'فشل الحصول على موقع GPS الحالي',
    'Categories': 'الفئات',
    'Select Category': 'اختر الفئة',
    'Select category': 'اختر الفئة',
    'No products found': 'لم يتم العثور على منتجات',
    'Just now': 'الآن',
    'minute ago': 'دقيقة مضت',
    'minutes ago': 'دقائق مضت',
    'hour ago': 'ساعة مضت',
    'hours ago': 'ساعات مضت',
    'day ago': 'يوم مضى',
    'days ago': 'أيام مضت',
    'week ago': 'أسبوع مضى',
    'weeks ago': 'أسابيع مضت',
    'month ago': 'شهر مضى',
    'months ago': 'أشهر مضت',
    'Confirm': 'تأكيد',
    'No categories found': 'لم يتم العثور على فئات',
    'Loading categories, please wait...': 'جارٍ تحميل الفئات، يرجى الانتظار...',
    'Loading categories...': 'جارٍ تحميل الفئات...',
    'No categories available': 'لا توجد فئات متاحة',
    'Product Images': 'صور المنتج',
    'You can add up to 5 product images': 'يمكنك إضافة حتى 5 صور للمنتج',
    'Product Name': 'اسم المنتج',
    'Enter product name': 'أدخل اسم المنتج',
    'Please enter product name': 'يرجى إدخال اسم المنتج',
    'Price': 'السعر',
    'Please enter price': 'يرجى إدخال السعر',
    'Add product description..': 'أضف وصف المنتج..',
    'Show price to customers in listings': 'إظهار السعر للزبائن في القوائم',
    'Is the product available for sale?': 'هل المنتج متاح للبيع؟',
    'Publish Product': 'نشر المنتج',
    'Add Images': 'إضافة صور',
    'Tap to upload': 'اضغط للرفع',
    'Please add at least one image': 'يرجى إضافة صورة واحدة على الأقل',
    'Please select a category': 'يرجى اختيار فئة',
    'Failed to delete product': 'فشل حذف المنتج',
    'Product updated successfully': 'تم تحديث المنتج بنجاح',
    'Product published successfully': 'تم نشر المنتج بنجاح',
    'Error selecting images': 'حدث خطأ أثناء اختيار الصور',
    'Set your location area or GPS in Edit Profile before posting.':
        'حدد منطقتك أو GPS في تعديل الملف قبل النشر.',
    'update': 'تحديث',
    'publish': 'نشر',
    'product': 'منتج',
    'This product already exists in the pack':
        'هذا المنتج موجود بالفعل في الباك',
    'Select pack products first': 'اختر منتجات الباك أولًا',
    'Enter pack name': 'أدخل اسم الباك',
    'Enter pack sale price': 'أدخل سعر بيع الباك',
    'Pack price must be less than the total price of products':
        'يجب أن يكون سعر الباك أقل من السعر الإجمالي للمنتجات',
    'Must login first': 'يجب تسجيل الدخول أولًا',
    'No store found for this user': 'لم يتم العثور على متجر لهذا المستخدم',
    'Pack updated successfully': 'تم تحديث الباك بنجاح',
    'Pack published successfully': 'تم نشر الباك بنجاح',
    'Error during publishing': 'خطأ أثناء النشر',
    'You haven\'t added any products to the pack yet':
        'لم تقم بإضافة أي منتجات إلى الباك بعد',
    'Use the search above to add products':
        'استخدم البحث أعلاه لإضافة المنتجات',
    'Pack Name *': 'اسم الباك *',
    'Pack Sale Price': 'سعر بيع الباك',
    'Delivery areas': 'مناطق التوصيل',
    'Select delivery areas (optional)': 'اختر مناطق التوصيل (اختياري)',
    'No areas selected — your store address will be used by default':
        'لم يتم اختيار مناطق — سيتم استخدام عنوان متجرك افتراضيًا',
    'Publish Pack': 'نشر الباك',
    'km radius': 'كم نطاق',
    'Filters': 'الفلاتر',
    'Reset': 'إعادة تعيين',
    'Sort By': 'ترتيب حسب',
    'Price Range': 'نطاق السعر',
    'Minimum Rating': 'أقل تقييم',
    'Apply Filters': 'تطبيق الفلاتر',
    'Results': 'النتائج',
    'No Results Found': 'لم يتم العثور على نتائج',
    'Try adjusting your search or filters to find what you\'re looking for':
        'جرّب تعديل البحث أو الفلاتر للعثور على ما تبحث عنه',
    'Clear Filters': 'مسح الفلاتر',
    'Customers can call you': 'يمكن للزبائن الاتصال بك',
    'Call button will be hidden': 'سيتم إخفاء زر الاتصال',
    'Customers can contact you': 'يمكن للزبائن التواصل معك',
    'Buttons will be hidden': 'سيتم إخفاء الأزرار',
    'Tap to select location': 'اضغط لاختيار الموقع',
    'Important: Nearby filter needs GPS coordinates. If GPS is not set, your products will not appear in distance search. Also, area search (Wilaya/Baladiya) depends on your address. If address is empty, your products will not appear in area filter.':
        'مهم: فلتر القرب يحتاج إحداثيات GPS. إذا لم يتم ضبط GPS فلن تظهر منتجاتك في البحث حسب المسافة. كما أن البحث حسب المنطقة (الولاية/البلدية) يعتمد على عنوانك. إذا كان العنوان فارغًا فلن تظهر منتجاتك في فلتر المنطقة.',
    'GPS coordinates selected': 'تم تحديد إحداثيات GPS',
    'GPS coordinates not selected yet': 'لم يتم تحديد إحداثيات GPS بعد',
    'Nearby search visibility': 'الظهور في البحث القريب',
    'Nearby results use your GPS. Turn this on to show your store by distance. You can turn it off anytime.':
        'نتائج القرب تستخدم GPS الخاص بك. فعّل هذا لإظهار متجرك حسب المسافة. يمكنك إيقافه في أي وقت.',
    'Show my store in nearby results': 'إظهار متجري في النتائج القريبة',
    'Visible in nearby results': 'ظاهر في النتائج القريبة',
    'Hidden from nearby results': 'مخفي من النتائج القريبة',
    'GPS location is saved': 'تم حفظ موقع GPS',
    'Set GPS location': 'تحديد موقع GPS',
    'Location updated successfully ✅': 'تم تحديث الموقع بنجاح ✅',
    'Could not get location': 'تعذر الحصول على الموقع',
    '✅ Profile saved successfully': '✅ تم حفظ الملف الشخصي بنجاح',
    'Edit Product': 'تعديل المنتج',
    'Publish New Product': 'نشر منتج جديد',
    'Name': 'الاسم',
    'Description': 'الوصف',
    'Enter your name': 'أدخل اسمك',
    'Describe your store...': 'صف متجرك...',
    'Newest': 'الأحدث',
    'Oldest': 'الأقدم',
    'Highest Rated': 'الأعلى تقييماً',
    'Lowest Price': 'الأقل سعراً',
    'Highest Price': 'الأعلى سعراً',
    'Top Rated': 'الأعلى تقييماً',
    'Loading usage status...': 'جارٍ تحميل حالة الاستخدام...',
    'Your current usage is unavailable right now.':
        'استخدامك الحالي غير متاح الآن.',
    'Each screen answers one clear question.':
        'كل شاشة تجيب عن سؤال واحد واضح.',
    'Hide plans': 'إخفاء الخطط',
    'Show more plans': 'عرض المزيد من الخطط',
    'No plans available right now': 'لا توجد خطط متاحة حاليا',
    'Please refresh in a moment to load the subscription catalog.':
        'يرجى التحديث بعد قليل لتحميل كتالوج الاشتراكات.',
    'of': 'من',
    'products used': 'منتجات مستخدمة',
    'Most Popular': 'الأكثر شعبية',
    'Featured exposure and core promotion tools.':
        'ظهور مميز وأدوات ترويج أساسية.',
    'Higher visibility in recommendations.': 'ظهور أعلى في التوصيات.',
    'DZD / month': 'دج / الشهر',
    'Up to': 'حتى',
    'Duration': 'المدة',
    'day': 'يوم',
    'days': 'أيام',
    'Ad Impr': 'مرات الظهور',
    'Start now': 'ابدأ الآن',
    '7 days free': '7 أيام مجانا',
    'Could not select images': 'تعذر اختيار الصور',
    'Please upload at least one receipt image':
        'يرجى رفع صورة إيصال واحدة على الأقل',
    'Request number': 'رقم الطلب',
    'Number copied': 'تم نسخ الرقم',
    'Plan information': 'معلومات الخطة',
    'Account number (RIB)': 'رقم الحساب (RIB)',
    'No need to type the number or take a screenshot.':
        'لا حاجة لكتابة الرقم أو أخذ لقطة شاشة.',
    'Open your banking app and start a transfer.':
        'افتح تطبيقك البنكي وابدأ عملية التحويل.',
    'Send the amount to this account.': 'أرسل المبلغ إلى هذا الحساب.',
    'Upload the receipt in the next step.': 'ارفع الإيصال في الخطوة التالية.',
    'Upload receipt image': 'رفع صورة الإيصال',
    'Tap to choose an image': 'اضغط لاختيار صورة',
    'Camera or gallery': 'الكاميرا أو المعرض',
    'Locating...': 'جارٍ تحديد الموقع...',
    'Today': 'اليوم',
    'Favorites': 'المفضلة',
    'Stay': 'مدة البقاء',
    'Store': 'المتجر',
    'Follows (Ad)': 'المتابعات (إعلان)',
    'Advertising': 'إعلان نشط',
    'What these numbers mean': 'ماذا تعني هذه الأرقام',
    'You have no active ads right now. Start with one clear product or pack.':
        'ليس لديك إعلانات نشطة حاليا. ابدأ بمنتج أو باك واضح.',
    'Your ads are active, but they still need reach. Review dates, placement, and budget.':
        'إعلاناتك نشطة، لكنها ما تزال تحتاج إلى وصول أكبر. راجع التواريخ والمكان والميزانية.',
    'People are seeing your ads, but clicks are still low. Improve the image, title, or offer.':
        'الناس يرون إعلاناتك، لكن النقرات ما تزال منخفضة. حسّن الصورة أو العنوان أو العرض.',
    'Your ads are getting both views and clicks. Keep budget on the products that move fastest.':
        'إعلاناتك تحصل على مشاهدات ونقرات. حافظ على الميزانية للمنتجات الأسرع حركة.',
    'Nearby performance improves when both your store GPS and address are complete.':
        'أداء القرب يتحسن عندما يكون GPS المتجر والعنوان مكتملين.',
    'Store location': 'موقع المتجر',
    'Store location (optional)': 'موقع المتجر (اختياري)',
    'Select wilaya and baladiya': 'اختر الولاية والبلدية',
    'Select wilaya and baladiya (optional)': 'اختر الولاية والبلدية (اختياري)',
    'Please choose wilaya and baladiya': 'يرجى اختيار الولاية والبلدية',
    'People searching in that baladiya will see your posts unless you enable delivery.':
        'الأشخاص الذين يبحثون في تلك البلدية سيرون منشوراتك ما لم تفعّل التوصيل.',
    'Choose the wilaya and baladiya where your store is based. If you do not support delivery, your posts will mainly appear to people searching in that baladiya.':
        'اختر الولاية والبلدية التي يقع فيها متجرك. إذا كنت لا تدعم التوصيل، فستظهر منشوراتك أساسا للأشخاص الذين يبحثون في تلك البلدية.',
    'You can skip this step for now. Add your wilaya and baladiya later if you want better local search visibility.':
        'يمكنك تخطي هذه الخطوة الآن. أضف الولاية والبلدية لاحقا إذا أردت ظهورا أفضل في البحث المحلي.',
    'Location is optional. If you add it, your posts can appear more accurately to people searching in that wilaya or baladiya.':
        'الموقع اختياري. إذا أضفته، يمكن أن تظهر منشوراتك بدقة أكبر للأشخاص الذين يبحثون في تلك الولاية أو البلدية.',
    'Change the dates or create a new ad to start collecting results.':
        'غيّر التواريخ أو أنشئ إعلانا جديدا لبدء جمع النتائج.',
    'Campaign': 'حملة',
    'AD': 'إعلان',
    'Unique': 'فريد',
    'Hour': 'الساعة',
    'Remaining': 'المتبقي',
    'No product performance data for this period.':
        'لا توجد بيانات أداء للمنتجات في هذه الفترة.',
    'Once ads collect views and clicks, product-level insights will appear here.':
        'عندما تجمع الإعلانات مشاهدات ونقرات، ستظهر هنا تحليلات على مستوى المنتج.',
    'Failed to open ad editor': 'تعذر فتح محرر الإعلان',
    'Tips': 'نصائح',
    'Choose high-demand products, reserve impression budget for fast movers, and keep the home-top placement for your most visual campaigns.':
        'اختر المنتجات عالية الطلب، وخصص ميزانية الظهور للمنتجات السريعة الحركة، واحتفظ بموضع أعلى الصفحة لحملاتك الأكثر جاذبية بصريا.',
    'Preset': 'قالب',
    'All dates': 'كل التواريخ',
    'Custom': 'مخصص',
    'Select Pack to Advertise': 'اختر الباك للإعلان',
    'Already has an active ad': 'لديه إعلان نشط بالفعل',
    'Ready for advertising': 'جاهز للإعلان',
    'Advertise': 'أعلن',
    'Search products…': 'ابحث عن المنتجات...',
    'Product Performance': 'أداء المنتجات',
    'العربية': 'العربية',
  };
}
