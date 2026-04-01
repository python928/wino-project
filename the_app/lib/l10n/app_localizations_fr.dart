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
  String get directionsToStore => 'Itineraire vers le magasin';

  @override
  String get mapLabel => 'Carte';

  @override
  String get openInGoogleMaps => 'Ouvrir dans Google Maps';

  @override
  String get locationDisabledTitle => 'La localisation est desactivee';

  @override
  String get locationDisabledMessage =>
      'Activez le service de localisation (GPS) depuis les parametres pour utiliser l\'itineraire.';

  @override
  String get openSettings => 'Ouvrir les parametres';

  @override
  String get close => 'Fermer';

  @override
  String get locationUnavailable => 'Aucune position disponible';

  @override
  String get unableToOpenGoogleMaps => 'Impossible d\'ouvrir Google Maps';

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

  @override
  String get authRegisterHeaderTitle => 'Creez votre compte';

  @override
  String get authRegisterHeaderSubtitle =>
      'Trois etapes rapides pour personnaliser le shopping et les offres proches.';

  @override
  String get authRegisterFooterPrompt => 'Vous avez deja un compte ?';

  @override
  String get authRegisterFooterAction => 'Se connecter';

  @override
  String get authProfileSetupHeaderTitle => 'Completez votre profil';

  @override
  String get authProfileSetupHeaderSubtitle =>
      'Ajoutez quelques details pour personnaliser vos resultats.';

  @override
  String get authProfileSetupBodySubtitle =>
      'Votre nom, votre date de naissance et vos centres d\'interet nous aident a adapter les produits, magasins et offres proches.';

  @override
  String get authStepPersonalTitle => 'Informations personnelles';

  @override
  String get authStepPersonalSubtitle =>
      'Commencez par l\'essentiel pour avoir un compte complet des le debut.';

  @override
  String get authStepAccountTitle => 'Informations du compte';

  @override
  String get authStepAccountSubtitle =>
      'Utilisez un numero joignable et un mot de passe securise.';

  @override
  String get authStepInterestsTitle => 'Centres d\'interet';

  @override
  String get authStepInterestsSubtitle =>
      'Choisissez jusqu\'a 6 categories pour ameliorer les recommandations et la decouverte a proximite.';

  @override
  String get authFieldFirstName => 'Prenom';

  @override
  String get authFieldFirstNameHint => 'Entrez votre prenom';

  @override
  String get authFieldLastName => 'Nom';

  @override
  String get authFieldLastNameHint => 'Entrez votre nom';

  @override
  String get authFieldFullName => 'Nom complet';

  @override
  String get authFieldFullNameHint => 'Entrez votre nom complet';

  @override
  String get authFieldBirthday => 'Date de naissance';

  @override
  String get authFieldBirthdayHint =>
      'Utilisez le jour, le mois et l\'annee tels qu\'ils figurent sur vos documents officiels.';

  @override
  String get authFieldDay => 'Jour';

  @override
  String get authFieldDayHint => 'JJ';

  @override
  String get authFieldMonth => 'Mois';

  @override
  String get authFieldMonthHint => 'MM';

  @override
  String get authFieldYear => 'Annee';

  @override
  String get authFieldYearHint => 'AAAA';

  @override
  String get authFieldGender => 'Genre';

  @override
  String get authGenderMale => 'Homme';

  @override
  String get authGenderFemale => 'Femme';

  @override
  String get authFieldPhone => 'Numero de telephone';

  @override
  String get authFieldPhoneHint => '0XXXXXXXXX';

  @override
  String get authFieldEmail => 'E-mail';

  @override
  String get authFieldEmailHint => 'Entrez votre adresse e-mail';

  @override
  String get authFieldPassword => 'Mot de passe';

  @override
  String get authFieldPasswordHint => 'Entrez votre mot de passe';

  @override
  String get authFieldConfirmPassword => 'Confirmer le mot de passe';

  @override
  String get authFieldConfirmPasswordHint =>
      'Saisissez a nouveau votre mot de passe';

  @override
  String get authFieldCategories => 'Categories preferees';

  @override
  String get authFieldCategoriesHint =>
      'Choisissez jusqu\'a 6 categories. Vous pourrez les modifier plus tard.';

  @override
  String get authCategoriesCta => 'Choisir vos categories preferees';

  @override
  String get authCategoriesRetry => 'Reessayer le chargement des categories';

  @override
  String get authCategoriesLoadError =>
      'Impossible de charger les categories pour le moment. Veuillez reessayer.';

  @override
  String get authActionCreateAccount => 'Creer le compte';

  @override
  String get authActionPrevious => 'Precedent';

  @override
  String get authRegistrationFailed =>
      'L\'inscription a echoue. Veuillez reessayer.';

  @override
  String get authProfileSaveError =>
      'Impossible d\'enregistrer votre profil. Veuillez reessayer.';

  @override
  String get authErrorRequired => 'Champ requis';

  @override
  String get authErrorNameRequired => 'Entrez votre nom complet';

  @override
  String get authErrorBirthdayRequired => 'Entrez votre date de naissance';

  @override
  String get authErrorBirthdayInvalid => 'Entrez une date valide';

  @override
  String get authErrorMustBe13 => 'Vous devez avoir au moins 13 ans';

  @override
  String get authErrorPhoneRequired => 'Entrez votre numero de telephone';

  @override
  String get authErrorPhoneInvalid =>
      'Utilisez le format 05XXXXXXXX / 06XXXXXXXX / 07XXXXXXXX';

  @override
  String get authErrorEmailRequired => 'Entrez votre adresse e-mail';

  @override
  String get authErrorEmailInvalid => 'Entrez une adresse e-mail valide';

  @override
  String get authErrorPasswordRequired => 'Entrez un mot de passe';

  @override
  String get authErrorPasswordMin => 'Utilisez au moins 6 caracteres';

  @override
  String get authErrorConfirmPasswordRequired => 'Confirmez votre mot de passe';

  @override
  String get authErrorPasswordsDoNotMatch =>
      'Les mots de passe ne correspondent pas';

  @override
  String get authErrorCategoriesRequired => 'Choisissez au moins 1 categorie';

  @override
  String authStepProgress(int current, int total) {
    return 'Etape $current sur $total';
  }

  @override
  String categoriesPickerSelectionCount(int selected, int max) {
    return '$selected sur $max selectionnees';
  }

  @override
  String categoriesPickerMaxReached(int max) {
    return 'Vous pouvez selectionner jusqu\'a $max categories.';
  }

  @override
  String categoriesPickerMinRequired(int min) {
    return 'Selectionnez au moins $min categories pour continuer.';
  }

  @override
  String categoriesPickerMaxHint(int max) {
    return 'Choisissez jusqu\'a $max categories.';
  }

  @override
  String get categoryPickerSearchSubtitle =>
      'Choisissez des categories pour affiner les resultats, ou laissez vide pour garder une recherche large.';

  @override
  String get categoryPickerProductSubtitle =>
      'Choisissez la categorie unique qui correspond le mieux a ce produit.';
}
