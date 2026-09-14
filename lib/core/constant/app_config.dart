/// Interruptor central de la generación de audiodocumentales.
///
/// Cuando [useFirebaseGeneration] es `true` la app deja de hablar con el
/// backend de Railway y llama a las Cloud Functions del proyecto
/// `sapere-f7150` (callable `startStory`). La voz ya no llega del servidor:
/// la pone el lector bimodal del dispositivo, por lo que los documentos
/// nuevos no traen `bukbukUrl`.
class AppConfig {
  static const bool useFirebaseGeneration = true;
  static const String functionsRegion = 'europe-west1';
}
