require('dotenv').config();

const { getDb } = require('../src/firebase');

const categories = [
  {
    id: 'xAf9Ou8hfBRq1jDePMnG',
    companyId: 'Company1',
    name: 'Accessories',
    isActive: true,
    createdAt: '2026-03-23T16:05:06.541Z',
    updatedAt: '2026-03-23T16:05:06.541Z',
  },
  {
    id: 'gr6quWvMcJl8JfgI5S7K',
    companyId: 'Company1',
    name: 'Accessory Tool',
    isActive: true,
    createdAt: '2026-03-23T16:05:25.945Z',
    updatedAt: '2026-03-23T16:05:25.945Z',
  },
  {
    id: '5eCraoXghHsIAgik1G5q',
    companyId: 'Company1',
    name: 'Architect Costs',
    isActive: true,
    createdAt: '2026-03-23T16:05:35.676Z',
    updatedAt: '2026-03-23T16:05:35.676Z',
  },
  {
    id: 'ib8bWlmnoOpu6XSTSiwL',
    companyId: 'Company1',
    name: 'Bath Fans',
    isActive: true,
    createdAt: '2026-03-23T16:05:44.249Z',
    updatedAt: '2026-03-23T16:05:44.249Z',
  },
];

const materialTemplatesByCategory = {
  Accessories: [
    { name: 'GPX 2-1/2" Trim Torx Screw 5Lb', brand: 'brand', price: 53.64, unit: 'pcs' },
    { name: 'Geocel Pro-Flex Clear', brand: '', price: 6.98, unit: 'pcs' },
  ],
  'Accessory Tool': [
    { name: 'Screwdriver Set', brand: 'Stanley', price: 14.99, unit: 'pcs' },
    { name: 'Measuring Tape 5m', brand: 'Bosch', price: 8.5, unit: 'pcs' },
  ],
  'Architect Costs': [
    { name: 'Site Survey Fee', brand: '', price: 120.0, unit: 'pcs' },
    { name: 'Blueprint Printing', brand: '', price: 25.0, unit: 'pcs' },
  ],
  'Bath Fans': [
    { name: 'Bathroom Exhaust Fan 6 inch', brand: 'Panasonic', price: 89.0, unit: 'pcs' },
    { name: 'Fan Duct Pipe 4 inch', brand: '', price: 12.5, unit: 'lft' },
  ],
};

function parseDate(value) {
  if (!value) return new Date();
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? new Date() : d;
}

async function seed() {
  const db = getDb();

  const dryRun = process.argv.includes('--dry');
  const hard = process.argv.includes('--hard');
  const companyIdOverride = (() => {
    const idx = process.argv.findIndex((a) => a === '--companyId');
    if (idx === -1) return null;
    return process.argv[idx + 1] || null;
  })();

  const finalCategories = categories.map((c) => ({
    ...c,
    companyId: companyIdOverride || c.companyId,
  }));

  const materialsToCreate = [];
  for (const c of finalCategories) {
    const templates = materialTemplatesByCategory[c.name] || [];
    for (const t of templates) {
      materialsToCreate.push({
        companyId: c.companyId,
        name: t.name,
        brand: t.brand || '',
        price: Number(t.price || 0),
        unit: t.unit || 'pcs',
        categoryId: c.id,
        createdBy: null,
        isActive: true,
        createdAt: parseDate(c.createdAt),
        updatedAt: parseDate(c.updatedAt),
      });
    }
  }

  if (dryRun) {
    process.stdout.write(`Dry run\n`);
    process.stdout.write(`Categories: ${finalCategories.length}\n`);
    process.stdout.write(`Materials: ${materialsToCreate.length}\n`);
    return;
  }

  if (hard) {
    const matsSnap = await db.collection('materials').where('companyId', '==', finalCategories[0]?.companyId || '').get();
    const catsSnap = await db.collection('categories').where('companyId', '==', finalCategories[0]?.companyId || '').get();

    const batch = db.batch();
    matsSnap.docs.forEach((d) => batch.delete(d.ref));
    catsSnap.docs.forEach((d) => batch.delete(d.ref));
    await batch.commit();
  }

  {
    const batch = db.batch();
    for (const c of finalCategories) {
      const ref = db.collection('categories').doc(c.id);
      batch.set(
        ref,
        {
          companyId: c.companyId,
          name: c.name,
          isActive: c.isActive !== false,
          createdAt: parseDate(c.createdAt),
          updatedAt: parseDate(c.updatedAt),
        },
        { merge: true }
      );
    }
    await batch.commit();
  }

  {
    const batch = db.batch();
    for (const m of materialsToCreate) {
      const ref = db.collection('materials').doc();
      batch.set(ref, m, { merge: true });
    }
    await batch.commit();
  }

  process.stdout.write(`Seeded categories: ${finalCategories.length}\n`);
  process.stdout.write(`Seeded materials: ${materialsToCreate.length}\n`);
}

seed().catch((e) => {
  process.stderr.write(`${e?.stack || e}\n`);
  process.exitCode = 1;
});
