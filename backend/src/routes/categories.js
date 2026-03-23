const express = require('express');

const { getDb } = require('../firebase');
const { toIso, cleanUndefined } = require('../utils/firestore');

const router = express.Router();

router.get('/', async (req, res, next) => {
  try {
    const { companyId, isActive } = req.query;
    if (!companyId) {
      return res.status(400).json({ error: 'companyId is required' });
    }

    const db = getDb();
    let q = db.collection('categories').where('companyId', '==', companyId);
    if (isActive !== undefined) q = q.where('isActive', '==', isActive === 'true' || isActive === '1');

    const snap = await q.orderBy('name').get();
    const items = snap.docs.map((d) => {
      const data = d.data();
      return {
        id: d.id,
        companyId: data.companyId || '',
        name: data.name || '',
        isActive: data.isActive !== false,
        createdAt: toIso(data.createdAt) || new Date().toISOString(),
        updatedAt: toIso(data.updatedAt) || new Date().toISOString(),
      };
    });

    res.json(items);
  } catch (e) {
    next(e);
  }
});

router.post('/', async (req, res, next) => {
  try {
    const body = req.body || {};
    if (!body.companyId) return res.status(400).json({ error: 'companyId is required' });
    if (!body.name) return res.status(400).json({ error: 'name is required' });

    const db = getDb();
    const now = new Date();

    const doc = cleanUndefined({
      companyId: String(body.companyId),
      name: String(body.name),
      isActive: body.isActive !== false,
      createdAt: now,
      updatedAt: now,
    });

    const ref = await db.collection('categories').add(doc);
    const saved = await ref.get();
    const data = saved.data();

    res.status(201).json({
      id: ref.id,
      ...data,
      createdAt: toIso(data.createdAt),
      updatedAt: toIso(data.updatedAt),
    });
  } catch (e) {
    next(e);
  }
});

router.put('/:id', async (req, res, next) => {
  try {
    const body = req.body || {};
    const { companyId } = body;
    if (!companyId) return res.status(400).json({ error: 'companyId is required' });

    const db = getDb();
    const ref = db.collection('categories').doc(req.params.id);
    const existing = await ref.get();
    if (!existing.exists) return res.status(404).json({ error: 'Not found' });

    const existingData = existing.data();
    if (existingData.companyId !== companyId) return res.status(404).json({ error: 'Not found' });

    const patch = cleanUndefined({
      name: body.name !== undefined ? String(body.name) : undefined,
      isActive: body.isActive !== undefined ? body.isActive !== false : undefined,
      updatedAt: new Date(),
    });

    await ref.set(patch, { merge: true });
    const saved = await ref.get();
    const data = saved.data();

    res.json({
      id: saved.id,
      ...data,
      createdAt: toIso(data.createdAt),
      updatedAt: toIso(data.updatedAt),
    });
  } catch (e) {
    next(e);
  }
});

router.delete('/:id', async (req, res, next) => {
  try {
    const { companyId, hard } = req.query;
    if (!companyId) return res.status(400).json({ error: 'companyId is required' });

    const db = getDb();
    const ref = db.collection('categories').doc(req.params.id);
    const existing = await ref.get();
    if (!existing.exists) return res.status(404).json({ error: 'Not found' });

    const data = existing.data();
    if (data.companyId !== companyId) return res.status(404).json({ error: 'Not found' });

    if (hard === 'true' || hard === '1') {
      await ref.delete();
      return res.status(204).send();
    }

    await ref.set({ isActive: false, updatedAt: new Date() }, { merge: true });
    res.status(204).send();
  } catch (e) {
    next(e);
  }
});

module.exports = router;
