// Card Management Feature Barrel Export

// Data Layer
export 'data/repositories/card_management_repository.dart';
export 'data/services/supabase_card_service.dart';

// Domain Layer
export 'domain/providers/card_management_provider.dart';
export 'domain/providers/card_enrichment_notifier.dart';
export 'domain/providers/card_enrichment_state.dart';
export 'domain/models/word_enrichment_result.dart';

// Presentation Layer
export 'presentation/screens/card_list_screen.dart';
export 'presentation/screens/card_creation_screen.dart';
export 'presentation/view_models/card_list_view_model.dart';
export 'presentation/view_models/card_creation_view_model.dart';
