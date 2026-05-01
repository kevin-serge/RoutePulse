import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../data/database_helper.dart';
import '../model/livraison_model.dart';
import '../model/user_model.dart';
import '../model/client_model.dart';
import '../model/vehicule_model.dart';

class LivraisonRepository {
  final DatabaseHelper db = DatabaseHelper();
  final SupabaseClient supabase = Supabase.instance.client;

  final _refreshController = StreamController<void>.broadcast();
  Stream<void> get onRefresh => _refreshController.stream;

  bool _isSyncing = false;
  RealtimeChannel? _realtimeChannel;

  // ──────────────────────────────────────
  // CONNECTIVITÉ
  // ──────────────────────────────────────
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  // ──────────────────────────────────────
  // AUTH (local SQLite)
  // ──────────────────────────────────────
  Future<User?> getUserByEmailAndPassword(
      String email, String password) async {
    return db.getUserByEmailAndPassword(email, password);
  }

  // ──────────────────────────────────────
  // LIVREURS
  // ──────────────────────────────────────
  Future<List<User>> getAllLivreurs() => db.getAllLivreurs();
  Future<List<User>> getLivreursDisponibles() => db.getLivreursDisponibles();

  Future<void> addLivreur(User user) async => db.addLivreur(user);

  Future<void> deleteLivreur(int id) async => db.deleteLivreur(id);

  Future<void> updateLivreurStatus(int userId, String status,
      {double? distance}) async {
    await db.updateLivreurStatus(userId, status, distance: distance);
  }

  // ──────────────────────────────────────
  // LIVRAISONS
  // ──────────────────────────────────────
  Future<List<Livraison>> getLivraisons() async {
    final local = await db.getAllLivraisons();
    Future.microtask(syncFromServer);
    return local;
  }

  Future<List<Livraison>> getLivraisonsByLivreur(int livreurId) async {
    final local = await db.getLivraisonsByLivreur(livreurId);
    Future.microtask(syncFromServer);
    return local;
  }

  Future<void> addLivraison(Livraison l) async {
    final id = await db.addLivraison(l);
    if (await isOnline()) await _syncOne(id);
    _refreshController.add(null);
  }

  Future<void> updateLivraison(Livraison l) async {
    await db.updateLivraison(l);
    if (await isOnline()) await _syncOne(l.id!);
    _refreshController.add(null);
  }

  Future<void> assignerLivraison(int id, int livreurId) async {
    await db.assignerLivraison(id, livreurId);
    if (await isOnline()) await _syncOne(id);
    _refreshController.add(null);
  }

  Future<void> updateStatut(int id, String statut,
      {String? motif, List<String>? photos}) async {
    await db.updateStatut(id, statut, motif: motif, photos: photos);
    if (await isOnline()) await _syncOne(id);
    _refreshController.add(null);
  }

  Future<void> deleteLivraison(int id) async {
    final l = await db.getLivraisonById(id);
    if (l == null) return;

    await db.softDeleteLivraison(id);

    if (await isOnline() && l.remoteId != null) {
      try {
        await supabase.from('livraisons').delete().eq('id', l.remoteId!);
        await db.markSynced(id, l.remoteId!);
      } catch (e) {
        // Sera retenté au prochain syncAll
        print('[DELETE ERROR] $e');
      }
    }
    _refreshController.add(null);
  }

  // ──────────────────────────────────────
  // SYNC LOCAL → CLOUD
  // ──────────────────────────────────────
  Future<void> _syncOne(int localId) async {
    try {
      final l = await db.getLivraisonById(localId);
      if (l == null) return;

      if (l.isDeleted && l.remoteId != null) {
        await supabase.from('livraisons').delete().eq('id', l.remoteId!);
        await db.markSynced(localId, l.remoteId!);
        return;
      }
      if (l.isDeleted) {
        await db.markSynced(localId, '');
        return;
      }

      final payload = {
        'client': l.client,
        'adresse': l.adresse,
        'statut': l.statut,
        'livreur_id': l.livreurId,
        'photos': jsonEncode(l.photos),
        'notes': l.notes,
        'motif_annulation': l.motifAnnulation,
        'creneau': l.creneau,
        'articles': l.articles,
      };

      if (l.remoteId == null) {
        final response = await supabase
            .from('livraisons')
            .insert(payload)
            .select('id')
            .single();
        await db.markSynced(localId, response['id'].toString());
      } else {
        await supabase
            .from('livraisons')
            .update(payload)
            .eq('id', l.remoteId!);
        await db.markSynced(localId, l.remoteId!);
      }
    } catch (e) {
      print('[SYNC ERROR] _syncOne($localId): $e');
    }
  }

  Future<void> syncAll() async {
    if (!await isOnline()) return;
    final unsynced = await db.getUnsyncedLivraisons();
    for (final l in unsynced) {
      await _syncOne(l.id!);
    }
  }

  // ──────────────────────────────────────
  // SYNC CLOUD → LOCAL
  // ──────────────────────────────────────
  Future<void> syncFromServer() async {
    if (!await isOnline() || _isSyncing) return;
    _isSyncing = true;
    try {
      final remote = await supabase.from('livraisons').select();
      for (final item in remote) {
        await db.upsertFromRemote(item);
      }
      _refreshController.add(null);
    } catch (e) {
      print('[SYNC ERROR] syncFromServer: $e');
    } finally {
      _isSyncing = false;
    }
  }

  // ──────────────────────────────────────
  // REALTIME
  // ──────────────────────────────────────
  void startRealtimeSync() {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = supabase
        .channel('livraisons_realtime')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'livraisons',
          callback: (payload) async {
            if (_isSyncing) return;
            await syncFromServer();
          },
        )
        .subscribe();
  }

  void dispose() {
    _realtimeChannel?.unsubscribe();
    _refreshController.close();
  }

  // ──────────────────────────────────────
  // CLIENTS
  // ──────────────────────────────────────
  Future<List<Client>> getAllClients() => db.getAllClients();
  Future<void> addClient(Client c) async => db.addClient(c);
  Future<void> updateClient(Client c) async => db.updateClient(c);
  Future<void> deleteClient(int id) async => db.deleteClient(id);

  // ──────────────────────────────────────
  // VEHICULES
  // ──────────────────────────────────────
  Future<List<Vehicule>> getAllVehicules() => db.getAllVehicules();
  Future<void> addVehicule(Vehicule v) async => db.addVehicule(v);
  Future<void> updateVehicule(Vehicule v) async => db.updateVehicule(v);
  Future<void> deleteVehicule(int id) async => db.deleteVehicule(id);

  // ──────────────────────────────────────
  // STATS
  // ──────────────────────────────────────
  Future<Map<String, int>> getStatsStatuts() => db.getStatsStatuts();
}
