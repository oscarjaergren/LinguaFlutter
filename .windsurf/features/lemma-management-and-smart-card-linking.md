# Lemma Management & Smart Card Linking

**Status**: Future Feature  
**Priority**: Medium  
**Complexity**: High  
**Dependencies**: Card Enrichment Service, AI/LLM Integration

---

## Problem Statement

Users often create duplicate or related cards without realizing connections between words:
- Inflected forms (e.g., `ging` as past tense of `gehen`)
- Derived words (e.g., `erfahren` from `fahren`)
- Separable prefix verbs (e.g., `ankommen` from `kommen`)
- Participles used as adjectives (e.g., `gewappnet` from `wappnen`)

This leads to:
- Redundant study sessions
- Missed learning opportunities (understanding word families)
- Inefficient card management

---

## Linguistic Foundation

### The 4-Rule Lemma Test

A word should be stored as a **separate card** (new lemma) when it fails any of these tests:

| Rule | Question | Example |
|------|----------|---------|
| **1. Meaning Survives** | Does core meaning remain unchanged? | `fahren` → `erfahren` ❌ (drive → experience) |
| **2. Grammar Stable** | Same word class and argument structure? | `kommen` → `bekommen` ❌ (come → receive) |
| **3. Native Predictability** | Can native speakers derive it from rules? | `gehen` → `ging` ✅ (predictable past) |
| **4. Stress/Morphology** | No stress shifts or separability changes? | `úmfahren` vs `umfáhren` ❌ (two meanings) |

### Key Distinction

**Inflection** (same card, rule-generated):
- Conjugation: `gehen` → `ging` → `gegangen`
- Declension: `Hund` → `Hunde`
- Separable prefixes: `ankommen` → `Ich komme an`

**Derivation** (new card, must memorize):
- Meaning shift: `stehen` → `verstehen` (stand → understand)
- Inseparable prefixes: `kommen` → `bekommen` (come → receive)
- Stress-based splits: `úmfahren` (bypass) vs `umfáhren` (run over)

---

## Implementation Phases

### Phase 1: Smart Search & Duplicate Prevention (MVP)

**Goal**: Prevent accidental duplicates at card creation time

**Features**:
1. **Fuzzy Search on Input**
   - Show similar existing cards as user types
   - Use Levenshtein distance (≤2 edits)
   - Substring matching for shared roots
   - Prefix matching (4+ characters)

2. **Similar Cards Panel**
   ```
   ┌─ Create New Card ────────────────────────┐
   │ Word: gewappnet                          │
   │                                           │
   │ 💡 Similar cards found:                  │
   │   • wappnen (verb) - to arm    [View]    │
   │   • bewaffnen (verb)          [View]    │
   │                                           │
   │ ○ This is related to an existing word   │
   │ ○ This is a completely new word         │
   │                                           │
   │ [Continue]                               │
   └───────────────────────────────────────────┘
   ```

3. **User Decision**
   - View existing card details
   - Choose to create new or link to existing
   - No forced merging

**Technical Implementation**:
```dart
class CardSimilarityService {
  List<CardModel> findSimilarCards(String query, {int maxResults = 5}) {
    return allCards
      .where((card) => _calculateSimilarity(query, card) > 0.7)
      .sorted((a, b) => _calculateSimilarity(query, b)
          .compareTo(_calculateSimilarity(query, a)))
      .take(maxResults)
      .toList();
  }
  
  double _calculateSimilarity(String query, CardModel card) {
    // Combine multiple similarity metrics:
    // - Levenshtein distance
    // - Shared prefix length
    // - Substring match
    // - Phonetic similarity (optional)
  }
}
```

**UI Changes**:
- Add "Similar Cards" section to `CardCreationScreen`
- Show inline suggestions as user types `frontText`
- Add "Link to existing card" option

---

### Phase 2: AI-Assisted Relationship Classification

**Goal**: Automatically detect and suggest relationships between cards

**Features**:
1. **Linguistic Analysis**
   - Detect inflection patterns (past tense, participles, plurals)
   - Identify prefix types (separable vs inseparable)
   - Recognize derivational relationships
   - Classify word relationships with confidence scores

2. **Smart Suggestions**
   ```
   ┌─ Smart Suggestion ───────────────────────┐
   │ 💡 "gewappnet" appears to be:            │
   │                                           │
   │ ✓ Past participle of "wappnen"          │
   │ ✓ Also used as adjective (prepared)     │
   │                                           │
   │ Recommendation:                           │
   │ → Link to "wappnen" card                │
   │   (as related form)                      │
   │                                           │
   │ [Accept] [Create separate anyway]        │
   │                                           │
   │ [Why?] ← Shows explanation               │
   └───────────────────────────────────────────┘
   ```

3. **Relationship Types**
   ```dart
   enum CardRelationshipType {
     inflection,      // Same lemma, different form
     derivation,      // Related meaning, different lemma
     compound,        // Compound word
     semanticFamily,  // Shared semantic field
     etymological,    // Historical relationship
     unrelated,       // False positive
   }
   
   class CardRelationship {
     final String sourceCardId;
     final String targetCardId;
     final CardRelationshipType type;
     final double confidence;  // 0.0 - 1.0
     final String explanation;
     final DateTime detectedAt;
   }
   ```

**Technical Implementation**:
```dart
class AICardRelationshipService {
  Future<CardRelationship?> analyzeRelationship(
    CardModel newCard,
    CardModel existingCard,
  ) async {
    // Use LLM or linguistic API to analyze:
    // - Morphological patterns
    // - Semantic similarity
    // - Grammatical function
    // - Usage frequency
    
    final prompt = '''
    Analyze the relationship between these German words:
    Word 1: ${newCard.frontText} (${newCard.backText})
    Word 2: ${existingCard.frontText} (${existingCard.backText})
    
    Determine:
    1. Relationship type (inflection/derivation/compound/unrelated)
    2. Confidence (0-100%)
    3. Brief explanation
    ''';
    
    // Call LLM API or use local linguistic rules
  }
}
```

**Data Model Extension**:
```dart
class CardModel {
  // ... existing fields ...
  
  // New fields for lemma management
  final String? lemmaId;  // Groups related cards
  final bool isBaseForm;  // Is this the dictionary form?
  final List<CardRelationship> relationships;
  
  // Enhanced WordData
  final WordData? wordData;  // Already exists, extend it
}

class WordData {
  // ... existing fields ...
  
  // New fields for inflection metadata
  final bool? isSeparable;
  final String? separablePrefix;
  final String? auxiliary;  // "haben" or "sein"
  final Map<String, String>? irregularForms;  // "past": "ging"
}
```

---

### Phase 3: Proactive Duplicate Detection

**Goal**: Detect and suggest merging duplicates after creation

**Features**:
1. **Background Scanning**
   - Periodic analysis of card collection
   - Detect potential duplicates or related cards
   - Generate merge/link suggestions

2. **Duplicate Notification**
   ```
   ┌─ Possible Duplicates Detected ───────────┐
   │ ⚠️ You have similar cards:               │
   │                                           │
   │ • gewappnet (adj, created today)         │
   │ • wappnen (verb, created last week)     │
   │                                           │
   │ Would you like to link these cards?     │
   │                                           │
   │ [Preview] [Link] [Ignore] [Not related] │
   └───────────────────────────────────────────┘
   ```

3. **Bulk Management Tools**
   - View all unlinked related cards
   - Batch link/merge operations
   - Relationship graph visualization

---

### Phase 4: Related Words UI Enhancement

**Goal**: Surface word relationships during study and review

**Features**:
1. **Related Words Section**
   ```
   ┌─ Card Details: gewappnet ────────────────┐
   │ Front: gewappnet                         │
   │ Back: prepared, armed                    │
   │                                           │
   │ 🔗 Related Words:                        │
   │   • wappnen (verb) - to arm             │
   │     └─ Base form (inflection)           │
   │   • Waffe (noun) - weapon               │
   │     └─ Etymologically related           │
   │   • bewaffnet (adj) - armed             │
   │     └─ Semantic family                  │
   │                                           │
   │ [+ Add related word]                     │
   └───────────────────────────────────────────┘
   ```

2. **Study Session Integration**
   - Show related cards after answering
   - "You also know: wappnen, Waffe"
   - Optional: Practice related words together

3. **Word Family View**
   - Visualize word relationships as a graph
   - Filter by relationship type
   - Navigate between related cards

---

## Cross-Language Considerations

### Works Well:
- **Germanic**: English, German, Dutch
  - Clear inflection patterns
  - Predictable prefix behavior (with caveats)
  
- **Romance**: French, Spanish, Italian
  - Regular conjugation paradigms
  - Clear infinitive forms

### Requires Adaptation:
- **Slavic**: Russian, Polish, Czech
  - Aspect pairs (imperfective/perfective are separate lemmas)
  - Complex case systems
  
- **Semitic**: Arabic, Hebrew
  - Root-and-pattern morphology
  - Multiple lemmas from same root
  
- **Agglutinative**: Turkish, Finnish, Hungarian
  - Extensive suffix chains
  - "Base form" creates explosion of forms

### Doesn't Apply:
- **Isolating**: Chinese, Vietnamese
  - No inflection (perfect for current model!)
  - Focus on compounds and semantic relationships

**Universal Principle**: If breaking a word creates ambiguity, don't break it.

---

## User Experience Principles

### 1. **Default to Separate Cards**
- When in doubt, create a new card
- Linking is easier than un-merging
- Beginners need immediate vocabulary access

### 2. **Progressive Disclosure**
- Phase 1: Simple duplicate detection
- Phase 2: AI suggestions (opt-in)
- Phase 3: Advanced relationship management

### 3. **No Forced Decisions**
- Always allow "Create anyway"
- Users know their learning needs best
- System assists, doesn't dictate

### 4. **Hide Linguistic Complexity**
- Don't use terms like "inflection" or "derivation" in UI
- Use plain language: "related form", "base word", "word family"
- Show examples, not grammar rules

---

## Technical Architecture

### Database Schema

```sql
-- New table for card relationships
CREATE TABLE card_relationships (
  id UUID PRIMARY KEY,
  source_card_id UUID REFERENCES cards(id),
  target_card_id UUID REFERENCES cards(id),
  relationship_type TEXT,  -- 'inflection', 'derivation', etc.
  confidence REAL,
  explanation TEXT,
  created_at TIMESTAMP,
  created_by TEXT,  -- 'user' or 'ai'
  
  UNIQUE(source_card_id, target_card_id)
);

-- New table for lemma groups
CREATE TABLE lemma_groups (
  id UUID PRIMARY KEY,
  base_card_id UUID REFERENCES cards(id),
  language TEXT,
  created_at TIMESTAMP
);

-- Link cards to lemma groups
CREATE TABLE lemma_group_members (
  lemma_group_id UUID REFERENCES lemma_groups(id),
  card_id UUID REFERENCES cards(id),
  is_base_form BOOLEAN,
  
  PRIMARY KEY(lemma_group_id, card_id)
);
```

### Service Layer

```dart
// New service for relationship management
class CardRelationshipService {
  final CardRepository _cardRepository;
  final AICardRelationshipService _aiService;
  
  Future<List<CardRelationship>> findRelationships(CardModel card);
  Future<void> linkCards(String cardId1, String cardId2, CardRelationshipType type);
  Future<void> unlinkCards(String cardId1, String cardId2);
  Future<List<CardModel>> getRelatedCards(String cardId);
}

// Extend existing CardManagementProvider
class CardManagementProvider {
  // ... existing methods ...
  
  // New methods
  Future<List<CardModel>> findSimilarCards(String query);
  Future<void> linkRelatedCards(String cardId1, String cardId2);
  Future<List<CardModel>> getCardFamily(String cardId);
}
```

---

## Implementation Checklist

### Phase 1 (MVP) - Smart Search
- [ ] Implement `CardSimilarityService` with fuzzy matching
- [ ] Add "Similar Cards" panel to `CardCreationScreen`
- [ ] Add "Link to existing card" option
- [ ] Store basic card relationships in database
- [ ] Add relationship display to card detail view

### Phase 2 (AI Enhancement)
- [ ] Integrate LLM API for relationship classification
- [ ] Implement `AICardRelationshipService`
- [ ] Add smart suggestion UI
- [ ] Store AI confidence scores
- [ ] Add linguistic explanation tooltips

### Phase 3 (Advanced)
- [ ] Background duplicate detection job
- [ ] Bulk relationship management UI
- [ ] Relationship graph visualization
- [ ] Merge/unmerge card tools
- [ ] Export word families

### Phase 4 (Study Integration)
- [ ] Show related cards during practice
- [ ] Add "word family" study mode
- [ ] Relationship-aware spaced repetition
- [ ] Related words in review sessions

---

## Success Metrics

- **Duplicate Reduction**: % decrease in duplicate cards created
- **Relationship Coverage**: % of cards with at least one relationship
- **User Engagement**: % of users who link cards
- **AI Accuracy**: Precision/recall of AI relationship suggestions
- **Study Efficiency**: Improved retention for linked word families

---

## Open Questions

1. **Should we auto-link obvious inflections?**
   - Pro: Reduces manual work
   - Con: May surprise users
   - **Decision**: Phase 2 feature, opt-in

2. **How to handle conflicting relationships?**
   - Example: User says "unrelated", AI says "inflection"
   - **Decision**: User always wins, store both opinions

3. **Should base forms be required?**
   - Pro: Cleaner data model
   - Con: Friction for casual users
   - **Decision**: Optional, encouraged via enrichment

4. **Cross-language relationship detection?**
   - Example: "Hund" (German) ↔ "hound" (English)
   - **Decision**: Phase 4 feature, low priority

---

## References

- Wiktionary API for conjugation data
- Levenshtein distance algorithm
- Linguistic lemmatization theory
- Spaced repetition research on word families

---

**Last Updated**: 2024-12-25  
**Author**: System Design  
**Review Status**: Draft
