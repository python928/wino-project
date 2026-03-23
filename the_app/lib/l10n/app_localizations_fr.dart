// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Wino';

  @override
  String get commonCancel => 'Annuler';

  @override
  String get commonClose => 'Fermer';

  @override
  String get commonSave => 'Enregistrer';

  @override
  String get commonRetry => 'Reessayer';

  @override
  String get commonSearch => 'Rechercher';

  @override
  String get commonLanguage => 'Langue';

  @override
  String get commonLoading => 'Chargement...';

  @override
  String get commonContinue => 'Continuer';

  @override
  String get commonNext => 'Suivant';

  @override
  String get commonStart => 'Commencer';

  @override
  String get commonSkip => 'Passer';

  @override
  String get commonOpenSettings => 'Ouvrir les parametres';

  @override
  String get commonBackToHome => 'Retour a l\'accueil';

  @override
  String get commonNotNow => 'Pas maintenant';

  @override
  String commonItemsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elements',
      one: '1 element',
      zero: 'Aucun element',
    );
    return '$_temp0';
  }

  @override
  String get profileSettingsEdit => 'Modifier les informations';

  @override
  String get profileSettingsScanQr => 'Scanner QR';

  @override
  String get profileSettingsSendFeedback => 'Envoyer un avis';

  @override
  String get profileSettingsLanguage => 'Langue';

  @override
  String get profileSettingsLogout => 'Se deconnecter';

  @override
  String get profileShareTitle => 'Partager le profil';

  @override
  String get profileShareShowQr => 'Afficher le QR du profil';

  @override
  String get profileShareCopyLink => 'Copier le lien';

  @override
  String get profileShareShare => 'Partager';

  @override
  String get profileShareLinkCopied => 'Lien du profil copie';

  @override
  String get productMenuFavoriteAdd => 'Ajouter aux favoris';

  @override
  String get productMenuFavoriteRemove => 'Retirer des favoris';

  @override
  String get productMenuShare => 'Partager le produit';

  @override
  String get productMenuReport => 'Signaler le produit';

  @override
  String get productShareQr => 'Afficher le QR du produit';

  @override
  String get productShareCopyLink => 'Copier le lien';

  @override
  String get productShareShare => 'Partager';

  @override
  String get productShareLinkCopied => 'Lien du produit copie';

  @override
  String get feedbackTitleSend => 'Envoyer un avis';

  @override
  String get feedbackTitleMy => 'Mes avis';

  @override
  String get feedbackSubmitSuccess => 'Avis envoye avec succes.';

  @override
  String get feedbackSubmitError => 'Echec de l\'envoi de l\'avis';

  @override
  String get feedbackEmpty => 'Aucun avis envoye pour le moment.';

  @override
  String get locationDisabled =>
      'La localisation est desactivee. Activez le GPS pour la recherche a proximite.';

  @override
  String get locationPermissionDeniedForever =>
      'L\'autorisation de localisation est refusee de facon permanente. Autorisez-la depuis les parametres de l\'application.';

  @override
  String get settingsOpenLocation => 'Ouvrir les parametres de localisation';

  @override
  String get settingsOpenApp => 'Ouvrir les parametres de l\'application';

  @override
  String get errorGenericTitle => 'Un probleme est survenu';

  @override
  String get networkErrorDetails =>
      'Veuillez verifier votre connexion puis reessayer.';

  @override
  String get serverErrorDetails =>
      'Desole, une erreur est survenue. Veuillez reessayer plus tard.';

  @override
  String get launchEyebrow => 'Bienvenue';

  @override
  String get launchTitle => 'Commencez dans votre langue';

  @override
  String get launchSubtitle =>
      'Choisissez la langue pour la navigation, la recherche et les outils marchand. Vous pourrez la modifier plus tard depuis le profil.';

  @override
  String get launchSearchTitle => 'Recherchez plus intelligemment';

  @override
  String get launchSearchDescription =>
      'Trouvez plus vite les produits, reductions et packs dans une seule place de marche locale.';

  @override
  String get launchNearbyTitle => 'Decouverte a proximite';

  @override
  String get launchNearbyDescription =>
      'Utilisez le GPS seulement quand vous voulez des resultats par distance et des offres proches.';

  @override
  String get launchPrivacyTitle => 'Controle de visibilite du magasin';

  @override
  String get launchPrivacyDescription =>
      'Les marchands choisissent si leur magasin apparait dans les resultats a proximite.';

  @override
  String get locationEducationNearbyTitle =>
      'Utiliser le GPS pour les resultats a proximite';

  @override
  String get locationEducationNearbyDescription =>
      'Nous utilisons votre position uniquement quand vous choisissez la recherche a proximite. Cela aide a calculer la distance jusqu\'aux magasins et packs autour de vous.';

  @override
  String get locationEducationStoreTitle =>
      'Definir la position GPS du magasin';

  @override
  String get locationEducationStoreDescription =>
      'Les coordonnees de votre magasin aident la recherche a proximite a montrer vos produits et vos packs aux bons clients.';

  @override
  String get locationEducationPrivacyNote =>
      'Vous gardez le controle. La visibilite a proximite peut etre desactivee plus tard depuis le profil du magasin.';

  @override
  String get locationEducationRadiusHint =>
      'La recherche a proximite a besoin du GPS une fois pour mesurer la distance avec precision.';

  @override
  String get locationEducationAddressHint =>
      'Les filtres de ville utilisent votre adresse enregistree, alors que les filtres a proximite utilisent le GPS.';

  @override
  String get profileTitle => 'Profil';

  @override
  String get profileTooltipShare => 'Partager le profil';

  @override
  String get profileTooltipAds => 'Tableau de bord des annonces';

  @override
  String get profileTooltipNotifications => 'Notifications';

  @override
  String get profileShareQrTitle => 'QR du magasin';

  @override
  String get profileSettingsChooseImageSource =>
      'Choisir la source de l\'image';

  @override
  String get profileSettingsCamera => 'Camera';

  @override
  String get profileSettingsGallery => 'Galerie';

  @override
  String get feedbackTypeLabel => 'Type d\'avis';

  @override
  String get feedbackTypeProblem => 'Probleme';

  @override
  String get feedbackTypeSuggestion => 'Suggestion';

  @override
  String get feedbackMessageLabel => 'Message';

  @override
  String get feedbackMessageHint => 'Decrivez le probleme ou votre suggestion.';

  @override
  String get feedbackAppVersionOptional =>
      'Version de l\'application (optionnel)';

  @override
  String get feedbackDeviceInfoOptional => 'Infos appareil (optionnel)';

  @override
  String get feedbackAttachScreenshotOptional =>
      'Joindre une capture d\'ecran (optionnel)';

  @override
  String get feedbackScreenshotSelected => 'Capture d\'ecran selectionnee';

  @override
  String get feedbackSending => 'Envoi...';

  @override
  String get feedbackWriteMessageRequired => 'Veuillez ecrire votre message.';

  @override
  String get feedbackLoadHistoryFailed =>
      'Impossible de charger l\'historique des avis.';

  @override
  String feedbackAdminNotePrefix(String note) {
    return 'Note admin: $note';
  }

  @override
  String get feedbackStatusOpen => 'Ouvert';

  @override
  String get feedbackStatusResolved => 'Resolu';

  @override
  String get feedbackStatusInReview => 'En cours d\'examen';

  @override
  String get feedbackStatusRejected => 'Rejete';

  @override
  String get feedbackTypeDefault => 'Avis';

  @override
  String get qrLinkOpened => 'Lien QR ouvert.';
}
