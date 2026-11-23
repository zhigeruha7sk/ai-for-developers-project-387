# Календарь звонков (продолжение)


[![hexlet-check](https://github.com/zhigeruha7sk/ai-for-developers-project-387/actions/workflows/hexlet-check.yml/badge.svg)](https://github.com/zhigeruha7sk/ai-for-developers-project-387/actions)

Интегрируйте работу агентов в GitHub проект

Учебный проект Хекслета: https://ru.hexlet.io/programs/ai-for-developers
Как это должно работать: https://files.hexlet.app/a/2ipc5m

## Публичная ссылка

Приложение развёрнуто и доступно по адресу:
**<https://calendar-production-2a3ad289.up.railway.app>**

- Гость: <https://calendar-production-2a3ad289.up.railway.app/booking>
- Админка владельца: <https://calendar-production-2a3ad289.up.railway.app/admin>
- Проверка сервиса: <https://calendar-production-2a3ad289.up.railway.app/api/health>
- Версия сборки: <https://calendar-production-2a3ad289.up.railway.app/api/version>

Ссылка ведёт на тот же сервис, который собирается из `Dockerfile`: Spring Boot отдаёт и API, и
собранный фронтенд.

## Стек

- Разное

## Установка

<!-- Опишите установку: клонирование, зависимости, переменные окружения -->

```bash
git clone https://github.com/zhigeruha7sk/ai-for-developers-project-387.git
cd ai-for-developers-project-387
```

## Использование

<!-- Добавьте примеры запуска и запись asciinema — именно это смотрит работодатель -->

---

## Воркфлоу GitHub Actions

Все автоматизации лежат в `.github/workflows/`. Файл `hexlet-check.yml` сгенерирован Хекслетом:
его нельзя редактировать, удалять или переименовывать репозиторий.

| Файл                        | Триггер                                              | Назначение                                     |
| --------------------------- | ---------------------------------------------------- | ---------------------------------------------- |
| `hexlet-check.yml`          | push в любую ветку и теги                             | проверка проекта Хекслетом                     |
| `opencode.yml`              | комментарий с `/oc` или `/opencode` в issue/строке PR | запуск агента OpenCode                         |
| `opencode-triage.yml`       | `issues: opened`                                      | автотриаж нового issue                         |
| `jactionlint.yml`           | push в `main` и любой `pull_request`                  | линт файлов GitHub Actions                     |

Секреты: `OPENCODE_API_KEY` — доступ к модели, `AGENT_PUSH_TOKEN` — PAT для записи меток,
комментариев и пуша из агента, `HEXLET_ID` — идентификатор проекта Хекслета.
`AGENT_PUSH_TOKEN` должен иметь право `workflow`: без него агент не сможет изменить файлы
в `.github/workflows/` (у `GITHUB_TOKEN` такого права нет).

<details>
<summary>Автоматические тесты Хекслета</summary>

Тесты запускаются на каждый коммит. За запуск отвечает файл `.github/workflows/hexlet-check.yml` — не удаляйте и не переименовывайте ни его, ни репозиторий.

</details>

<details>
<summary>Интеграция OpenCode: агент по команде в комментарии</summary>

Файл `.github/workflows/opencode.yml` запускает агента OpenCode по команде `/oc` или `/opencode`
в комментарии к issue или к строке PR. Описание и ответ агента появляются тем же комментарием
в ветке обсуждения.

- **Кто может запустить**: только участники с ролями OWNER, MEMBER, COLLABORATOR —
  комментарий чужого автора джобу не запускает; внутри действия дополнительно проверяется
  право на запись в репозитории.
- **Триггеры**: `issue_comment` и `pull_request_review_comment`; тайм-аут — 1440 минут,
  чекаут — с `fetch-depth: 1`.
- **Модель и ключ**: `opencode-go/deepseek-v4.1-flash` (провайдер OpenCode Go), ключ берётся из секрета
  `OPENCODE_API_KEY` (значение хранится в настройках репозитория и в код не попадает).
- **Приватность**: публикация сессии на opencode.ai отключена явно (`share: 'false'`).
- **Безопасность**: у джобы только `contents: write`, `issues: write` и
  `pull-requests: write`, чекаут — с `persist-credentials: false`, запуски по одной задаче
  выполняются по очереди (группа `concurrency` по номеру issue/PR).
- **Токены**: сам агент авторизуется через `OPENCODE_API_KEY`, а git-пуш и обращения к GitHub —
  через `TOKEN`, `GH_TOKEN` и `GITHUB_TOKEN`, которые берутся из `AGENT_PUSH_TOKEN` с откатом
  на `GITHUB_TOKEN`. Для правки файлов в `.github/workflows/` у PAT должно быть право `workflow`.
- **Коммиты агента**: шаг `Configure git identity` выставляет `user.name`/`user.email`
  (`opencode-agent[bot]`); без него `git commit` в раннере падает с `Author identity unknown`.
- **Пуш агента**: шаг `Configure git credentials` прописывает в `.git/config` заголовок
  `AUTHORIZATION` с `AGENT_PUSH_TOKEN`. При `use_github_token: true` сам opencode git-креденшелы
  не настраивает, а чекаут идёт с `persist-credentials: false`, поэтому без этого шага
  `git push` падает с `could not read Username for 'https://github.com'`.
- **Автотриаж**: комментарий с маркером `<!-- opencode-auto-triage -->` запускает отдельного
  агента `triage`; выбор делается через input `agent` (`triage` при маркере, пусто для ручных
  `/oc` и `/opencode`, которые по-прежнему используют обычного агента).
- **Линт workflow-файлов**: `.github/workflows/jactionlint.yml` проверяет файлы Actions
  через закреплённый `jdx/jactionlint` v2.6.0 на push в `main` и на каждый pull request;
  та же проверка входит в `mise run check`.

Пример: `/oc объясни, что делает этот репозиторий`.

</details>

<details>
<summary>Автотриаж новых обращений</summary>

Файл `.github/workflows/opencode-triage.yml` реагирует на `issues: opened` и запускает разбор
нового issue по скиллу triage. Вручную такой workflow не запускается и комментарии не слушает.

- **Фильтры**: только issues (PR игнорируются), только авторы-люди (боты пропускаются).
  Обращения с метками `skip-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`
  или `wontfix` не триажатся. Job-level `if` читает payload события `opened` и работает как
  быстрый фильтр, но не видит метки, поставленные позже.
- **Подготовка**: шаг `Require AGENT_PUSH_TOKEN` падает сразу, если секрет не задан, затем
  делается чекаут `main`, чтобы в workspace был доступен `.github/scripts/triage-guard.sh`.
- **Перепроверка живого состояния**: прямо перед записью шаг `Re-check live issue state`
  запускает `.github/scripts/triage-guard.sh`, который перечитывает issue через API. Если issue
  оказался PR, его автор — бот или стоит любая из меток выше, шаг завершается успешно, а
  `needs-triage` и комментарий не добавляются. Метка `needs-triage` не блокирует — её ставит
  сам workflow. Агент `triage` повторяет ту же проверку первым шагом.
- **Что делает**: ставит метку `needs-triage` и публикует комментарий
  `/oc <!-- opencode-auto-triage --> …`; этот комментарий подхватывает `opencode.yml`.
  Если автотриаж для конкретного issue не нужен, владелец добавляет метку `skip-triage`.
- **Как триажит**: агент работает по скиллу `.agents/skills/triage/SKILL.md` и его
  `AGENT-BRIEF.md`/`OUT-OF-SCOPE.md`. Каждый комментарий триажа начинается с
  `> *This was generated by AI during triage.*`. У issue остаётся ровно одна категорийная
  метка (`bug` или `enhancement`) и ровно одна state-метка (`needs-triage`, `needs-info`,
  `ready-for-agent`, `ready-for-human`, `wontfix`). Для `ready-for-agent` публикуется agent
  brief по `AGENT-BRIEF.md`; при совпадении с `.out-of-scope/` ставится `wontfix` с
  объяснением в комментарии.
- **Права**: у джобы `permissions: {}` — токен `GITHUB_TOKEN` не используется. Комментарий
  публикуется через `AGENT_PUSH_TOKEN` (обязательный секрет): комментарий от
  `github-actions[bot]` не запускает `opencode.yml`, а комментарий от владельца PAT запускает.
- **Ограничения**: тайм-аут 5 минут, `concurrency` по номеру issue, без отмены уже идущего
  запуска.
- **Ограничения агента**: отдельный агент `triage` в `opencode.json` не может править файлы
  (`edit`/`write`), запускать суб-агентов и задавать вопросы. Из shell разрешены только
  `gh issue view|list|comment|edit|close|reopen`, `gh label list` и read-only команды
  `git`/`ls`/`rg`; опасные обходы `rg --pre` и `git diff --output` запрещены. Он не меняет
  код, не создаёт ветки, коммиты и PR.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
