import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import '../data/database_helper.dart';
import '../model/livraison_model.dart';
import '../model/user_model.dart';

class LivraisonRepository {
  final DatabaseHelper db = DatabaseHelper();
  final SupabaseClient supabase = Supabase.instance.client;

  // ========================
  // CONNECTIVITE
  // ========================
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ========================
  // AUTH
  // ========================
  Future<User?> getUserByEmailAndPassword(String email, String password) async {
    return await db.getUserByEmailAndPassword(email, password);
  }

  // ========================
  // LIVREURS
  // ========================
  Future<List<User>> getAllLivreurs() async {
    return await db.getAllLivreurs();
  }

  Future<List<User>> getLivreursDisponibles() async {
    return await db.getLivreursDisponibles();
  }

  Future<void> addLivreur(User user) async {
    await db.addLivreur(user);
  }

  Future<void> deleteLivreur(int id) async {
    await db.deleteLivreur(id);
  }

  Future<void> updateLivreurStatus(int userId, String status,
      {double? distance}) async {
    await db.updateLivreurStatus(userId, status, distance: distance);
  }

  // ========================
  // LIVRAISONS (LOCAL FIRST)
  // ========================
  Future<List<Livraison>> getAllLivraisons() async {
    return await db.getAllLivraisons();
  }

  Future<List<Livraison>> getLivraisons() async {
    return await db.getAllLivraisons();
  }

  Future<List<Livraison>> getLivraisonsByLivreur(int livreurId) async {
    return await db.getLivraisonsByLivreur(livreurId);
  }

  Future<List<Livraison>> getLivraisonsDuJour({int? livreurId}) async {
    return await db.getLivraisonsDuJour(livreurId);
  }

  Future<void> addLivraison(Livraison livraison) async {
    final id = await db.addLivraison(livraison);
    if (await isOnline()) {
      await _syncOne(id);
    }
  }

  Future<void> updateLivraison(Livraison livraison) async {
    await db.updateLivraison(livraison);
    if (await isOnline() && livraison.remoteId != null) {
      await _updateRemote(livraison);
    }
  }

  Future<void> updateStatut(int id, String statut,
      {String? motif, List<String>? photos}) async {
    await db.updateStatut(id, statut, motif: motif, photos: photos);

    if (await isOnline()) {
      await _syncOne(id);
    }
  }

  Future<void> assignerLivraison(int livraisonId, int livreurId) async {
    await db.assignerLivraison(livraisonId, livreurId);
    if (await isOnline()) {
      await _syncOne(livraisonId);
    }
  }

  Future<void> deleteLivraison(int id) async {
    await db.deleteLivraison(id);
  }

  // ========================
  // STATS
  // ========================
  Future<Map<String, int>> getStatsStatuts() async {
    return await db.getStatsStatuts();
  }

  Future<int> countLivraisons() async {
    final all = await db.getAllLivraisons();
    return all.length;
  }

  Future<int> countLivreurs() async {
    final all = await db.getAllLivreurs();
    return all.length;
  }

  // ========================
  // SYNC SUPABASE
  // ========================
  Future<void> _syncOne(int localId) async {
    try {
      final all = await db.getAllLivraisons();
      final l = all.firstWhere((x) => x.id == localId);

      if (l.remoteId == null) {
        // INSERT
        final response = await supabase
            .from('livraisons')
            .insert({
              'client_nom': l.client,
              'adresse': l.adresse,
              'statut': l.statut,
              'livreur_id': l.livreurId,
              'photos': l.photos.join(','),
              'notes': l.notes,
              'motif_annulation': l.motifAnnulation,
              'creneau': l.creneau,
              'articles': l.articles,
            })
            .select()
            .single();

        await db.markSynced(localId, response['id'].toString());
      } else {
        // UPDATE
        await supabase.from('livraisons').update({
          'statut': l.statut,
          'livreur_id': l.livreurId,
          'photos': l.photos.join(','),
          'notes': l.notes,
          'motif_annulation': l.motifAnnulation,
        }).eq('id', l.remoteId!);

        await db.markSynced(localId, l.remoteId!);
      }
    } catch (e) {
      // Offline ou erreur Supabase → on laisse isSynced=0, sera retenté plus tard
    }
  }

  Future<void> _updateRemote(Livraison l) async {
    try {
      await supabase.from('livraisons').update({
        'statut': l.statut,
        'livreur_id': l.livreurId,
        'photos': l.photos.join(','),
        'notes': l.notes,
        'motif_annulation': l.motifAnnulation,
      }).eq('id', l.remoteId!);
    } catch (_) {}
  }

  Future<void> syncAll() async {
    if (!await isOnline()) return;
    final unsynced = await db.getUnsyncedLivraisons();
    for (final l in unsynced) {
      await _syncOne(l.id!);
    }
  }

  /// Sync temps réel descendante (cloud → local)
  void startRealtimeSync() {
    supabase.from('livraisons').stream(primaryKey: ['id']).listen((data) async {
      for (var item in data) {
        final l = Livraison(
          client: item['client_nom'] ?? '',
          adresse: item['adresse'] ?? '',
          statut: item['statut'] ?? 'en_attente',
          livreurId: item['livreur_id'],
          remoteId: item['id']?.toString(),
          isSynced: 1,
          notes: item['notes'],
          creneau: item['creneau'],
          articles: item['articles'],
        );
        await db.addLivraison(l);
      }
    });
  }
}
