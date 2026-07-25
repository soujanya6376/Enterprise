import { NestFactory } from '@nestjs/core';
import { ValidationPipe, Logger } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { join } from 'path';
import * as express from 'express';
import { AppModule } from './app.module';
import { AllExceptionsFilter } from './common/filters/all-exceptions.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';
import { TransformInterceptor } from './common/interceptors/transform.interceptor';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  const config = app.get(ConfigService);

  const apiPrefix = config.get<string>('API_PREFIX', 'api');
  const apiVersion = config.get<string>('API_VERSION', 'v1');
  app.setGlobalPrefix(`${apiPrefix}/${apiVersion}`);

  app.enableCors({ origin: config.get('CORS_ORIGIN', '*') });

  app.useGlobalPipes(
    new ValidationPipe({
      whitelist: true,
      forbidNonWhitelisted: true,
      transform: true,
      transformOptions: { enableImplicitConversion: true },
    }),
  );
  app.useGlobalFilters(new AllExceptionsFilter());
  app.useGlobalInterceptors(new LoggingInterceptor(), new TransformInterceptor());

  // Serve uploaded files
  const uploadDir = config.get<string>('UPLOAD_DIR', './uploads');
  app.use('/uploads', express.static(join(process.cwd(), uploadDir.replace('./', ''))));

  // Swagger
  const swaggerConfig = new DocumentBuilder()
    .setTitle('POS Billing API')
    .setDescription('Point of Sale billing system API')
    .setVersion('1.0')
    .addBearerAuth()
    .build();
  const document = SwaggerModule.createDocument(app, swaggerConfig);
  SwaggerModule.setup(`${apiPrefix}/docs`, app, document);

  const port = config.get<number>('PORT', 3000);
  await app.listen(port);
  Logger.log(`API running on http://localhost:${port}/${apiPrefix}/${apiVersion}`, 'Bootstrap');
  Logger.log(`Swagger docs at http://localhost:${port}/${apiPrefix}/docs`, 'Bootstrap');
}
bootstrap();
