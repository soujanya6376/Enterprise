import { BadRequestException, Injectable } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import * as ExcelJS from 'exceljs';
import { PrismaService } from '../../prisma/prisma.service';

interface RowError {
  row: number;
  errors: string[];
}

export interface ImportSummary {
  totalRows: number;
  insertedRows: number;
  skippedRows: number;
  failedRows: number;
  errors: RowError[];
}

const HEADERS = ['Name', 'Description', 'Price', 'TaxPercentage'];

@Injectable()
export class ProductImportService {
  constructor(private prisma: PrismaService) {}

  async buildTemplate(): Promise<Buffer> {
    const wb = new ExcelJS.Workbook();
    const ws = wb.addWorksheet('Products');
    ws.addRow(HEADERS);
    ws.addRow(['Coffee', 'Hot Coffee', 100, 5]);
    ws.getRow(1).font = { bold: true };
    ws.columns.forEach((c) => (c.width = 20));
    return (await wb.xlsx.writeBuffer()) as unknown as Buffer;
  }

  async importFromBuffer(file: Express.Multer.File, userId: string): Promise<ImportSummary> {
    if (!file) throw new BadRequestException('No file uploaded');
    const wb = new ExcelJS.Workbook();
    await wb.xlsx.load(file.buffer as any);
    const ws = wb.worksheets[0];
    if (!ws) throw new BadRequestException('Empty workbook');

    const errors: RowError[] = [];
    const toInsert: Prisma.ProductCreateManyInput[] = [];
    let totalRows = 0;
    let skippedRows = 0;

    // Map header columns by name (row 1).
    const headerRow = ws.getRow(1);
    const colIndex: Record<string, number> = {};
    headerRow.eachCell((cell, col) => {
      const key = String(cell.value ?? '').trim();
      if (key) colIndex[key] = col;
    });
    for (const h of ['Name', 'Price']) {
      if (!colIndex[h]) throw new BadRequestException(`Missing required column: ${h}`);
    }

    // Pre-load existing names for duplicate skipping.
    const existing = new Set(
      (await this.prisma.product.findMany({ where: { deletedAt: null }, select: { name: true } })).map((p) =>
        p.name.toLowerCase(),
      ),
    );
    const seenInFile = new Set<string>();

    for (let r = 2; r <= ws.rowCount; r++) {
      const row = ws.getRow(r);
      const name = String(row.getCell(colIndex['Name'] ?? 1).value ?? '').trim();
      const description = colIndex['Description'] ? String(row.getCell(colIndex['Description']).value ?? '').trim() : '';
      const priceRaw = colIndex['Price'] ? row.getCell(colIndex['Price']).value : null;
      const taxRaw = colIndex['TaxPercentage'] ? row.getCell(colIndex['TaxPercentage']).value : null;

      if (!name && priceRaw === null) continue; // blank row
      totalRows++;

      const rowErrors: string[] = [];
      if (!name) rowErrors.push('Name is required');
      const price = Number(priceRaw);
      if (priceRaw === null || priceRaw === '' || Number.isNaN(price) || price < 0)
        rowErrors.push('Price must be a non-negative number');

      let tax: number | null = null;
      if (taxRaw !== null && taxRaw !== '' && taxRaw !== undefined) {
        tax = Number(taxRaw);
        if (Number.isNaN(tax) || tax < 0 || tax > 100) rowErrors.push('TaxPercentage must be 0–100');
      }

      if (rowErrors.length) {
        errors.push({ row: r, errors: rowErrors });
        continue;
      }

      const lower = name.toLowerCase();
      if (existing.has(lower) || seenInFile.has(lower)) {
        skippedRows++;
        continue;
      }
      seenInFile.add(lower);
      toInsert.push({
        name,
        description: description || null,
        price: new Prisma.Decimal(price),
        taxPercentage: tax === null ? null : new Prisma.Decimal(tax),
      });
    }

    if (toInsert.length) {
      await this.prisma.product.createMany({ data: toInsert });
    }

    const summary: ImportSummary = {
      totalRows,
      insertedRows: toInsert.length,
      skippedRows,
      failedRows: errors.length,
      errors,
    };

    await this.prisma.productImportLog.create({
      data: {
        uploadedById: userId,
        fileName: file.originalname,
        totalRows,
        insertedRows: toInsert.length,
        skippedRows,
        failedRows: errors.length,
        errors: errors as unknown as Prisma.InputJsonValue,
      },
    });

    return summary;
  }
}
