import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';

/**
 * Leaves already-shaped paginated payloads ({ data, meta }) untouched and
 * passes everything else through. Kept intentionally light so binary/stream
 * responses (PDF, HTML) are not wrapped.
 */
@Injectable()
export class TransformInterceptor implements NestInterceptor {
  intercept(_context: ExecutionContext, next: CallHandler): Observable<any> {
    return next.handle().pipe(map((data) => data));
  }
}
