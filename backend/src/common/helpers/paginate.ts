import { PaginationDto, buildMeta } from '../dto/pagination.dto';

type PrismaDelegate = {
  findMany: (args: any) => Promise<any[]>;
  count: (args: any) => Promise<number>;
};

export async function paginate<T>(
  delegate: PrismaDelegate,
  args: { where?: any; orderBy?: any; select?: any; pagination: PaginationDto },
) {
  const { where, orderBy, select, pagination } = args;
  const [data, total] = await Promise.all([
    delegate.findMany({ where, orderBy, select, skip: pagination.skip, take: pagination.limit }),
    delegate.count({ where }),
  ]);
  return { data, meta: buildMeta(total, pagination.page, pagination.limit) };
}
