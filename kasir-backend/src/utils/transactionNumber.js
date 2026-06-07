/**
 * Generator nomor transaksi unik
 * Format: TRX-YYYYMMDD-XXXXX (contoh: TRX-20241201-00001)
 */
const generateTransactionNumber = async (queryFn) => {
  const today = new Date();
  const dateStr = today.toISOString().slice(0, 10).replace(/-/g, '');
  const prefix = `TRX-${dateStr}`;

  // Cari transaksi terakhir hari ini
  const result = await queryFn(
    `SELECT transaction_number FROM transactions
     WHERE transaction_number LIKE $1
     ORDER BY transaction_number DESC
     LIMIT 1`,
    [`${prefix}-%`]
  );

  let sequence = 1;
  if (result.rows.length > 0) {
    const lastNumber = result.rows[0].transaction_number;
    const lastSequence = parseInt(lastNumber.split('-').pop());
    sequence = lastSequence + 1;
  }

  return `${prefix}-${String(sequence).padStart(5, '0')}`;
};

module.exports = { generateTransactionNumber };