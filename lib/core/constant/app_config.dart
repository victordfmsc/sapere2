/// Configuracion de las Cloud Functions del proyecto `sapere-f7150`.
///
/// La generacion de audiodocumentales (`startStory`), el texto de comunidad
/// (`generateCommunityText`) y las flashcards (`generateFlashcards`) pasan por
/// estas callables: la app ya no llama a Railway. La voz la pone el lector
/// bimodal del dispositivo, por lo que los documentos nuevos no traen
/// `bukbukUrl`.
class AppConfig {
  static const String functionsRegion = 'europe-west1';
}
