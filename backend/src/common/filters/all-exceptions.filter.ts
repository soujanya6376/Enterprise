import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Prisma } from '@prisma/client';

@Catch()
export class AllExceptionsFilter implements ExceptionFilter {
  private readonly logger = new Logger('ExceptionFilter');

  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const response = ctx.getResponse();
    const request = ctx.getRequest();

    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message: string | string[] = 'Internal server error';
    let error = 'Internal Server Error';

    if (exception instanceof HttpException) {
      status = exception.getStatus();
      const res = exception.getResponse() as any;
      message = res?.message ?? exception.message;
      error = res?.error ?? exception.name;
    } else if (exception instanceof Prisma.PrismaClientKnownRequestError) {
      if (exception.code === 'P2002') {
        status = HttpStatus.CONFLICT;
        message = `Unique constraint failed on: ${(exception.meta as any)?.target}`;
        error = 'Conflict';
      } else if (exception.code === 'P2025') {
        status = HttpStatus.NOT_FOUND;
        message = 'Record not found';
        error = 'Not Found';
      } else {
        status = HttpStatus.BAD_REQUEST;
        message = 'Database request error';
        error = 'Bad Request';
      }
    }

    if (status >= 500) {
      this.logger.error(exception instanceof Error ? exception.stack : String(exception));
    }

    response.status(status).json({
      statusCode: status,
      message,
      error,
      path: request.url,
      timestamp: new Date().toISOString(),
    });
  }
}
