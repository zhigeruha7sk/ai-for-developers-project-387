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
| `opencode.yml`              | комментарий с `/oc` или `/opencode` в issue/обсуждении PR | запуск агента OpenCode                     |
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
в комментарии к issue или к обсуждению PR (событие `issue_comment`; inline-комментарии к строке
кода намеренно не подключены, потому что они чекаутят merge-коммит PR). Описание и ответ агента
появляются тем же комментарием в ветке обсуждения.

- **Кто может запустить**: только участники с ролями OWNER, MEMBER, COLLABORATOR —
  комментарий чужого автора джобу не запускает. Проверка выполняется в job-level `if` по
  `author_association`; действие `opencode/github` свою проверку прав пропускает, когда ему
  передан `TOKEN`.
- **Модель и ключ**: `opencode-go/deepseek-v4.1-flash` (провайдер OpenCode Go), ключ берётся из секрета
  `OPENCODE_API_KEY` (значение хранится в настройках репозитория и в код не попадает).
- **Приватность**: публикация сессии на opencode.ai отключена явно (`share: 'false'`).
- **Безопасность**: у ручной job `opencode` только `contents: write`, `issues: write` и
  `pull-requests: write`; у `review` — `contents: read`, `issues: write` (комментарий
  публикуется через issues-эндпоинт, `pull-requests: write` не нужен),
  `pull-requests: read` (для `gh pr view/diff/checks`), `checks: read`,
  `statuses: read`; у `triage` — `contents: read`, `issues: write`. Чекаут — с
  `persist-credentials: false`. Ручные запуски по одной задаче
  выполняются по очереди; авторевью имеет отдельную группу и отменяет устаревший запуск при
  новом коммите.
- **Токены**: сам агент авторизуется через `OPENCODE_API_KEY`, а git-пуш и обращения к GitHub —
  через `TOKEN`, `GH_TOKEN` и `GITHUB_TOKEN`, которые берутся из `AGENT_PUSH_TOKEN` с откатом
  на `GITHUB_TOKEN`. Для правки файлов в `.github/workflows/` у PAT должно быть право `workflow`.
- **Коммиты агента**: шаг `Configure git identity` (только в ручной job) выставляет
  `user.name`/`user.email` (`opencode-agent[bot]`); без него `git commit` в раннере падает
  с `Author identity unknown`.
- **Пуш агента**: шаг `Configure git credentials` прописывает в `.git/config` заголовок
  `AUTHORIZATION` с `AGENT_PUSH_TOKEN` только в ручной job. Чекаут идёт с
  `persist-credentials: false`, поэтому без этого шага `git push` падает с
  `could not read Username for 'https://github.com'`. Действие `opencode/github` само пишет
  токен в `.git/config` на время сессии и восстанавливает конфиг в конце; поэтому в
  `review` и `triage` передаётся только эфемерный `GITHUB_TOKEN`, а PAT — нет.
- **Автотриаж и авторевью**: комментарий с маркером автотриажа запускает отдельного агента
  `triage`, с маркером авторевью — агента `review`; ручные `/oc` и `/opencode` по-прежнему
  используют обычного агента.
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
- **Права**: у job запроса `permissions: {}` — токен `GITHUB_TOKEN` не используется.
  Комментарий публикуется через `AGENT_PUSH_TOKEN` (обязательный секрет): комментарий от
  `github-actions[bot]` не запускает `opencode.yml`, а комментарий от владельца PAT запускает.
  Сама job `triage` получает `contents: read` и `issues: write` и работает с эфемерным
  `GITHUB_TOKEN`, без PAT.
- **Ограничения**: тайм-аут job запроса 5 минут, `concurrency` по номеру issue, без отмены
  уже идущего запуска; агент `triage` ограничен 30 минутами. У агента `triage` запрещены
  `external_directory` (абсолютные пути вне репозитория), встроенные `read`/`glob`/`grep`/
  `list`, `rg`, подстановки команд `$(...)`/бэктики, цепочки `;` и обходы
  `--no-index`/`--output`; файлы читаются через `git show HEAD:<path>`, поиск — через
  `git grep` по отслеживаемым файлам. Команды с `.git` отклоняются. `git remote`
  ограничен формами `-v`/`get-url`.
- **Ограничения агента**: отдельный агент `triage` в `opencode.json` не может править файлы
  (`edit`/`write`), запускать суб-агентов и задавать вопросы. Из shell разрешены только
  `gh issue view|list|comment|edit|close|reopen`, `gh label list` и read-only команды
  `git`/`ls`/`rg`; опасные обходы `rg --pre` и `git diff --output` запрещены. Он не меняет
  код, не создаёт ветки, коммиты и PR.

</details>

<details>
<summary>Авторевью пулл-реквестов</summary>

Файл `.github/workflows/opencode-review.yml` реагирует на `pull_request_target`
(`opened`, `synchronize`, `reopened`, `ready_for_review`, `edited`) и запускает независимый
разбор каждого PR по критериям `REVIEW.md`. Событие `edited` перезапускает ревью после
правки тела PR, включая разделы «Риск» и «Откат».

- **Почему `pull_request_target`**: для same-repo PR событие `pull_request` заставляет
  GitHub брать сам workflow из ветки PR. Владелец ветки мог бы заменить
  `opencode-review.yml`, добавить свой шаг и вывести `AGENT_PUSH_TOKEN`. На
  `pull_request_target` GitHub берёт определение workflow из базовой ветки PR, поэтому
  подменить его из самого PR нельзя. Граница доверия: авторевью включено только для PR с
  базой = дефолтная ветка (`github.event.pull_request.base.ref ==
  github.event.repository.default_branch`); для другой базы workflow исполнялся бы из
  ветки, которую автор PR может изменить. Альтернатива `workflow_run` тоже безопасна, но
  `pull_request_target` сразу даёт номер PR и его метаданные без отдельного запуска-моста.
- **PR-код не исполняется**: job запроса не делает checkout и не запускает скрипты,
  тесты или сборки из PR. Он читает только номер PR и имя репозитория из контекста
  события и публикует заранее заданный текст комментария.
- **Фильтры**: черновики пропускаются до `ready_for_review`. PR из форков не
  авторевьюятся. Из ботов исключены только Dependabot и Renovate (как шум); остальные
  боты и PR, созданные агентом OpenCode, ревьюятся как обычные.
- **Как устроено**: job запроса работает с `permissions: {}` и публикует через
  `AGENT_PUSH_TOKEN` комментарий с `/oc` и маркером авторевью. Комментарий от
  `github-actions[bot]` не запускает `opencode.yml`, поэтому нужен PAT с правом
  комментировать PR. `opencode.yml` видит маркер и запускает отдельную job `review`
  с агентом `review`. Перед публикацией job запроса читает `opencode.yml` из дефолтной
  ветки через API и пропускает запрос, если базовый workflow ещё не содержит обработчик
  маркера. Ошибка API (500, rate limit) — это ошибка шага, а не «маркера нет», иначе
  транзиентный сбой молча выключил бы авторевью. Это делает роллаут двухфазным: сначала
  в базовую ветку попадают job `review` и `REVIEW.md`, только потом начинают
  публиковаться триггеры.
- **Лимит ревью**: `.github/scripts/review-guard.sh` считает предыдущие
  триггер-комментарии на PR и не даёт позвать модель больше
  `MAX_AUTO_REVIEWS_PER_PR` раз (repo variable, по умолчанию 3). Считаются только
  комментарии с ролью OWNER/MEMBER/COLLABORATOR, иначе посторонние исчерпали бы лимит.
  Проверка выполняется дважды: в job запроса до публикации триггера и в job `review` до
  вызова модели, чтобы ручной комментарий с маркером не обошёл лимит. Старые триггеры не
  удаляются, иначе счётчик всегда был бы нулевым.
- **Где используется PAT**: только в job запроса — в проверке лимита, в проверке базового
  workflow и в вызове `gh pr comment`. Остальные шаги и job `review` получают эфемерный
  `GITHUB_TOKEN`; PAT в `.git/config` ревьюера не попадает. Действие записывает туда
  `GITHUB_TOKEN` на время сессии, поэтому агенту `review` запрещены встроенные
  `read`/`glob`/`grep`/`list` и обходы через shell: прочитать `.git/config`
  разрешёнными командами нельзя (см. ниже).
- **Конфиг ревьюера из базовой ветки**: job `review` сначала сохраняет
  `opencode.json` из базовой ветки (`git show origin/<default>:opencode.json`) во
  временный файл, затем запускает действие с `OPENCODE_CONFIG` на этот файл и с
  отключённым обнаружением проектного конфига (`OPENCODE_DISABLE_PROJECT_CONFIG` и
  `OPENCODE_CONFIG_PROJECT_DISABLE`). Поэтому ветка PR не может подменить агента
  `review`, его промпт или права через свой `opencode.json`, `.opencode/` или `.agents/`.
  Из сохранённой копии удаляется `mcp`, поэтому ревьюер не обращается к внешним
  MCP-инструментам (включая Railway), даже если они описаны в базовом конфиге.
- **Критерии**: `REVIEW.md` в корне репозитория. Job `review` делает checkout с
  `fetch-depth: 0` и читает версию из базовой ветки (`git show origin/<default>:REVIEW.md`),
  чтобы PR не мог подменить критерии. Если файла в базовой ветке нет, PR считается
  bootstrap-изменением, которое этот файл и добавляет: ревьюер читает его через
  `git show HEAD:REVIEW.md` только для разбора самого bootstrap-PR и обязан добавить
  пометку `Bootstrap: REVIEW.md ещё нет в базовой ветке, критерии взяты из PR.` сразу после
  дисклеймера. Как только
  файл появляется в базовой ветке, версия из PR не используется. Разбор идёт по двум осям:
  спецификация (`docs/spec.md`, issue, ADR) и стандарты (`AGENTS.md`, `REVIEW.md`).
- **До мержа**: пока `opencode-review.yml` есть только в ветке PR, авторевью не
  запустится: `pull_request_target` берёт workflow из базовой ветки. Job запроса
  дополнительно проверяет, что базовый `opencode.yml` уже умеет обрабатывать маркер, и
  иначе ничего не публикует. Поэтому после мержа сначала включается job `review`, а
  триггеры начинают работать только со следующего PR. В этом PR job `review` ни разу не
  запускался в Actions: независимый разбор коммита `69e191c` получен локальным запуском
  `opencode run --agent review` и приложен комментарием; живой прогон job нужен после
  мержа.
- **Формат**: первая строка `> *This was generated by AI during automatic review.*`, затем
  итог, находки с severity, `file:line` и пунктом `REVIEW.md`, отдельно «Проверено» и
  «Не проверено».
- **Права и ограничения**: у job запроса `permissions: {}` и запись только через PAT;
  тайм-аут 5 минут. Job `review` получает `contents: read`, `issues: write`,
  `pull-requests: read`, `checks: read`, `statuses: read` и эфемерный `GITHUB_TOKEN`, а не
  `AGENT_PUSH_TOKEN`;
  PAT в `.git/config` ревьюера не попадает. Агент `review` в `opencode.json` работает
  только на чтение: `edit`/`write`, встроенные `read`, `glob`, `grep` и `list`,
  суб-агенты, вопросы и внешние запросы запрещены. Shell ограничен read-only командами
  `gh`/`git`; файлы читаются через `git show`, `git grep` (только отслеживаемые файлы) и
  `git diff`, произвольный `rg` и абсолютные пути недоступны. Запись и запуск внешних
  программ через `--output`, `--pre`, `--no-index`, `--ext-diff`, `--textconv`,
  `--filters`, `git grep -O`/`--open-files-in-pager` и изменяющие формы
  `git branch`/`git remote` запрещены; любые команды, содержащие `.git/`, тоже
  запрещены. Он не запускает тесты и скрипты из PR, не одобряет и не запрашивает
  изменения, не меняет метки. Job `review` запускается только на `issue_comment` для PR
  (`github.event.issue.pull_request != null`) и чекаутит `ref` дефолтной ветки, поэтому
  `.github/scripts/review-guard.sh` не может прийти из кода PR.
- **Проверка read-only**: правила проверены на копии конфига агента `review` с подставным
  секретом в `.git/config`. `git diff --no-index .git/config ...`,
  `git diff --output=...`, `git show .git/config`, подстановки команд `$(...)`/бэктики,
  цепочки `;` и `read`-инструмент блокируются, а обычные `git diff <base>...HEAD`,
  `git log --pretty` и `git show <rev>:<path>` работают. `deny`-правила идут после
  `allow`, поэтому последнее совпадение закрывает обход.
- **Тайм-аут и отмена**: запуск job `review` ограничен 20 минутами. При новом коммите
  `concurrency` по номеру PR отменяет устаревшее ревью (`cancel-in-progress: true`);
  ручные `/oc` не отменяются и сохраняют прежний тайм-аут.
- **Шаблон PR**: `.github/pull_request_template.md` требует заполнить проверки, риск и
  способ отката. Авторевью — это комментарий, а не формальное одобрение: решение о мерже
  принимает человек.

</details>

<details>
<summary>Плановый аудит развёрнутого приложения</summary>

Файл `.github/workflows/app-audit.yml` запускает агента `audit` по расписанию и вручную.
Он проверяет развёрнутое приложение по `APP_URL` и заводит issue только по новой находке.

- **Триггеры**: `schedule` с cron `0 3 * * *` (03:00 UTC = 08:00 Asia/Almaty, не чаще
  одного раза в сутки) и `workflow_dispatch`. Файл лежит в `main`, поэтому кнопка
  «Run workflow» доступна в Actions, а расписание включено.
- **Адрес приложения**: repository variable `APP_URL` =
  `https://calendar-production-2a3ad289.up.railway.app`. Секретом она не является: адрес
  публичный и должен быть виден в логе. Если переменная не задана или `/api/health` не
  отвечает, workflow падает до вызова модели.
- **Права и авторизация**: у workflow `permissions: {}`, у job — только `contents: read`
  (чекаут и prompt) и `issues: write` (поиск и создание issue). Модель авторизуется
  секретом `OPENCODE_API_KEY`; GitHub CLI получает эфемерный `GITHUB_TOKEN`, PAT не
  используется. Агент `audit` в `opencode.json` не может править код (`edit: deny`),
  запускать суб-агентов, задавать вопросы и ходить во внешнюю сеть; `write` разрешён, но
  prompt ограничивает его файлами отчёта, а коммитов workflow не делает. Shell ограничен
  `curl`, `jq`, `cat`, `ls`, `rg`, `date`, `mkdir`, `gh issue list/view` и вызовом
  `.github/scripts/audit-issue.sh`.
- **Ограничения**: job — 25 минут, шаг агента — 15 минут; `concurrency: app-audit` с
  `cancel-in-progress: false` ставит второй аудит в очередь и не запускает два
  параллельно. CLI `opencode` ставится из закреплённого GitHub Release v1.19.6, SHA-256
  ассета проверяется перед распаковкой; установка vendor-скриптом не используется.
- **Что проверяет**: `GET /api/health` (200, `status: UP`), `GET /api/meeting-types`
  (200, непустой массив с `id`, `name`, `durationMinutes`), `/booking` и `/admin`
  (200, `text/html`, `<div id="root">`), а также `GET /api/version`, который README
  публикует как «Версия сборки». Полный чек-лист и правила отчёта —
  `.github/prompts/app-audit.md`.
- **Куда сохраняется результат**: агент пишет `.audit/report.md`, `.audit/agent-output.log`
  и сырые ответы в `.audit/evidence/`. Каталог `.audit/` в `.gitignore`, поэтому отчёты
  не попадают в коммиты. Каждый прогон загружает артефакт
  `app-audit-<run_id>-<attempt>` (срок хранения 30 дней) и публикует отчёт в summary
  запуска. Скачать артефакт можно со страницы запуска.
- **Дедупликация issue**: агент не вызывает `gh issue create` напрямую. Он передаёт
  находку в `.github/scripts/audit-issue.sh`, а скрипт ищет среди issues с меткой
  `app-audit` маркер `<!-- app-audit-finding:<ключ> -->`. Ключ стабилен (например,
  `readme-api-version`), заголовок может меняться — поэтому повторный прогон печатает
  `existing #<номер>` и не создаёт второй issue. По инструкции при отсутствии находок
  issue не создаётся, а в отчёте пишется «Находок нет»; это учебный сценарий без находки.

#### Результаты запусков

- Первый успешный ручной запуск из `main`, который создал issue:
  https://github.com/zhigeruha7sk/ai-for-developers-project-387/actions/runs/45118890531
- Повторный запуск с теми же данными (дедупликация):
  https://github.com/zhigeruha7sk/ai-for-developers-project-387/actions/runs/45119041721
- Ручной запуск кнопкой **Run workflow** из `main`:
  https://github.com/zhigeruha7sk/ai-for-developers-project-387/actions/runs/45124654450
- Созданный issue:
  https://github.com/zhigeruha7sk/ai-for-developers-project-387/issues/23
- Артефакты: `app-audit-45118890531-1`, `app-audit-45119041721-1` и
  `app-audit-45124654450-1` на страницах соответствующих запусков. В первом отчёте:
  «Найдено находок: 1. Создано issues: 1»; в повторных — «Найдено находок: 1.
  Создано issues: 0. Уже существовало: 1».
- Находка: `GET /api/version` отвечает 404, хотя README публикует этот адрес как
  «Версия сборки». Это реальная находка, поэтому учебный сценарий «находок нет» в
  прогоне не понадобился; логика для него описана выше.

#### Личные выводы

- **Что потребовало уточнений**. Штатное действие `anomalyco/opencode/github` в
  закреплённой версии принимает только `issue_comment` и `pull_request_review_comment`,
  поэтому `schedule`/`workflow_dispatch` им не запустить. Пришлось вызывать
  `opencode run` напрямую: это дало явный prompt, отдельный agent-профиль и контроль над
  артефактами.
- **Что изменилось в настройках**. Добавил repository variable `APP_URL`, метку
  `app-audit`; секрет `OPENCODE_API_KEY` уже существовал. В workflow задал
  `timeout-minutes`, `concurrency`, минимальные `permissions`, а установку CLI
  закрепил версией и SHA-256 после того, как jactionlint отклонил непроверяемый
  vendor-скрипт и `npm install` без lock-файла.
- **Что изменилось в постановке задачи**. Формулировку «агент создаёт issue» пришлось
  сузить: право на создание issue отдано отдельному проверяемому скрипту с маркером,
  а не свободному `gh issue create` в руках модели. Это делает дедупликацию
  детерминированной, а вывод агента — воспроизводимым.
- **Что показал первый прогон**. Агент корректно нашёл 404 и создал issue, но job упал
  на summary: `AUDIT_RUN_URL` был объявлен только в шаге агента, а `upload-artifact`
  по умолчанию не берёт скрытый `.audit/`. После переноса переменной в общий `env` и
  включения `include-hidden-files: true` повторный прогон стал зелёным.
- **Проверка кнопкой**. Запуск через **Run workflow** из `main`
  (run 45124654450) прошёл с тем же результатом: отчёт сохранён в артефакте,
  issue #23 найден по маркеру, новый issue не создан.
- **Ограничение доверия**. Отчёт и issue формирует модель, поэтому они полезны как
  сигнал, но не заменяют проверку человеком. Аудит намеренно ограничен публичными
  GET-запросами и не пишет в приложение.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
