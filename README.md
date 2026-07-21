# Lego App — fundação

Esta é a base de dados + camada de repositório da app. Ainda não tem UI —
é o "motor" sobre o qual vamos construir o dashboard a seguir.

## Estrutura

```
lib/data/
  database.dart                    -> tabelas Drift (Temas, Sets) + queries agregadas
  providers.dart                   -> ligação Riverpod (o que a UI vai consumir)
  repositories/
    sets_repository.dart           -> interface abstrata (contrato)
    drift_sets_repository.dart     -> implementação local com SQLite
  services/
    xlsx_import_service.dart       -> lê o teu .xlsx e devolve LegoSet prontos
```

## Como pôr a correr

1. Cria o projeto Flutter (se ainda não existir) e copia estes ficheiros
   para dentro da pasta `lib/`, e o `pubspec.yaml` para a raiz:

   ```bash
   flutter create lego_app
   cd lego_app
   # copiar pubspec.yaml e lib/ para aqui, substituindo os existentes
   ```

2. Instala as dependências:

   ```bash
   flutter pub get
   ```

3. Gera o código do Drift (cria `lib/data/database.g.dart`):

   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

   Nota: sempre que alterares uma tabela em `database.dart`
   (novo campo, nova tabela), tens de correr este comando outra vez.

4. Confirma que compila:

   ```bash
   flutter analyze
   ```

## Porquê esta estrutura

- **A UI nunca vai falar diretamente com o Drift.** Fala sempre com
  `SetsRepository` (a interface). Isto é o que vai permitir adicionar
  Firebase mais tarde sem reescrever ecrãs.
- **"Desconto %" e "Margem de venda" não são guardados** — são calculados
  em `LegoSet.descontoPercent` / `LegoSet.margemVendaPercent` a partir dos
  valores base, para nunca ficarem dessincronizados se editares um preço.
- **`XlsxImportService` está isolado da UI de propósito** — dá para testar
  a conversão de dados sozinha, sem correr a app inteira.

## Próximos passos sugeridos

1. Ecrã "Importar ficheiro" que usa `XlsxImportService` +
   `setsRepositoryProvider` para carregar o teu xlsx atual para a BD local.
2. Ecrã de lista de sets (`todosOsSetsProvider`), com adicionar/editar/apagar.
3. Dashboard: cartões de totais (`totalComprasProvider`, `totalVendasProvider`)
   + gráficos (`comprasPorAnoProvider`, `comprasPorTemaProvider`) com `fl_chart`.
4. Comparação de períodos: um ecrã simples com dois seletores de intervalo
   de datas, chamando `repository.totalComprasEntre(...)` duas vezes.
5. Export: serviço espelho do import (`XlsxExportService`), a gerar
   um `.xlsx` a partir de `todosOsSetsProvider`.
6. Mais tarde: `FirebaseSetsRepository` implementando a mesma interface,
   trocada em `providers.dart`.
