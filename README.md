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
| `opencode-review.yml`       | `pull_request_target` (`opened`, `synchronize`, …)    | запрос независимого авторевью PR               |
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
  комментарий чужого автора джобу не запускает. Проверка выполняется в job-level `if` по
  `author_association`; действие `opencode/github` свою проверку прав пропускает, когда ему
  передан `TOKEN`.
- **Триггер**: только `issue_comment`; тайм-аут ручной job — 1440 минут, чекаут — с
  `fetch-depth: 1`. Событие `pull_request_review_comment` намеренно не подключено: для него
  GitHub задаёт `GITHUB_REF=refs/pull/<N>/merge`, и `actions/checkout` положил бы в workspace
  merge-коммит PR до запуска агента с `AGENT_PUSH_TOKEN`. Поэтому `/oc` в комментарии к
  строке кода не работает — используйте обсуждение PR. Jobs `triage` и `opencode` явно
  проверяют `github.event_name == 'issue_comment'`, job `review` (авторевью) тоже ограничена
  `issue_comment`; review-путь стартует только с комментария `/oc`, который публикует job
  запроса авторевью.
- **Модель и ключ**: `opencode-go/deepseek-v4.1-flash` (провайдер OpenCode Go), ключ берётся из секрета
  `OPENCODE_API_KEY` (значение хранится в настройках репозитория и в код не попадает).
- **Приватность**: публикация сессии на opencode.ai отключена явно (`share: 'false'`).
- **Безопасность**: у ручной job `opencode` только `contents: write`, `issues: write` и
  `pull-requests: write`; у `review` — `contents: read`, `issues: read`,
  `pull-requests: write`, `checks: read`, `statuses: read`; у `triage` — `contents: read`,
  `issues: write`. Чекаут — с `persist-credentials: false`. Ручные запуски по одной задаче
  выполняются по очереди; авторевью имеет отдельную группу и отменяет устаревший запуск при
  новом коммите.
- **Токены**: сам агент авторизуется через `OPENCODE_API_KEY`, а git-пуш и обращения к GitHub —
  через `TOKEN`, `GH_TOKEN` и `GITHUB_TOKEN`, которые в ручной job берутся из
  `AGENT_PUSH_TOKEN` с откатом на `GITHUB_TOKEN`. Для правки файлов в `.github/workflows/`
  у PAT должно быть право `workflow`.
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
  уже идущего запуска; агент `triage` ограничен 30 минутами.
- **Ограничения агента**: отдельный агент `triage` в `opencode.json` не может править файлы
  (`edit`/`write`), запускать суб-агентов и задавать вопросы. Из shell разрешены только
  `gh issue view|list|comment|edit|close|reopen`, `gh label list` и read-only команды
  `git`/`ls`/`rg`; опасные обходы `rg --pre` и `git diff --output` запрещены. Он не меняет
  код, не создаёт ветки, коммиты и PR.

</details>

<details>
<summary>Авторевью пулл-реквестов</summary>

Файл `.github/workflows/opencode-review.yml` реагирует на `pull_request_target`
(`opened`, `synchronize`, `reopened`, `ready_for_review`) и запускает независимый разбор
каждого PR по критериям `REVIEW.md`.

- **Почему `pull_request_target`**: для same-repo PR событие `pull_request` заставляет
  GitHub брать сам workflow из ветки PR. Владелец ветки мог бы заменить
  `opencode-review.yml`, добавить свой шаг и вывести `AGENT_PUSH_TOKEN`. На
  `pull_request_target` GitHub всегда берёт определение workflow из базовой ветки, поэтому
  подменить job запроса из PR нельзя. Альтернатива `workflow_run` тоже безопасна, но
  `pull_request_target` сразу даёт номер PR и его метаданные без отдельного запуска-моста.
- **PR-код не исполняется**: job запроса не делает checkout и не запускает скрипты,
  тесты или сборки из PR. Он читает только номер PR, имя репозитория и комментарии PR
  через API, после чего публикует заранее заданный текст комментария. Инвариант относится
  к job запроса авторевью. Ручная job `opencode` тоже не получает код PR как начальный
  checkout: единственный её триггер — `issue_comment`, где `actions/checkout` берёт базовую
  ветку. Ветку PR действие открывает уже после старта, как и задумано для сборки.
- **Фильтры**: черновики пропускаются до `ready_for_review`. PR из форков не
  авторевьюятся, а Dependabot и Renovate пропускаются как шум. PR, созданные агентом
  OpenCode, ревьюятся как обычные.
- **Лимит запусков**: не больше 3 запросов авторевью на один PR по умолчанию
  (переменная репозитория `MAX_AUTO_REVIEWS_PER_PR`, иначе 3). Общий guard
  `.github/scripts/review-guard.sh` считает прежние комментарии-триггеры. Job запроса
  запускает его из базовой ветки через API до публикации нового комментария, поэтому
  четвёртый запрос не создаётся. Job `review` в `opencode.yml` повторяет подсчёт перед
  вызовом модели, поэтому ручной комментарий с маркером тоже не обходит лимит; текущий
  комментарий исключается из счётчика, чтобы третье разрешённое ревью всё ещё
  запускалось. Лимит считается по попыткам авторевью (комментариям-триггерам), включая
  отменённые: серия быстрых пушей не создаёт бесконечную очередь запусков. Ручные `/oc`
  без маркера авторевью не ограничиваются.
- **Guard из базовой ветки**: job `review` читает `.github/scripts/review-guard.sh` из
  базовой ветки (`git show origin/<default>:...`) во временный файл и исполняет только его.
  Это defense-in-depth: после `3dd1156` job `review` уже ограничена `issue_comment` и её
  checkout запинен на базовую ветку, поэтому guard из кода PR не исполняется. Коммит
  `b921cfb` не закрывает существующую уязвимость, а лишь сужает поверхность атаки.
- **Как устроено**: job запроса работает с `permissions: {}` и публикует через
  `AGENT_PUSH_TOKEN` комментарий с `/oc` и маркером авторевью. Комментарий от
  `github-actions[bot]` не запускает `opencode.yml`, поэтому нужен PAT с правом
  комментировать PR. `opencode.yml` видит маркер и запускает отдельную job `review`
  с агентом `review`.
- **Где используется PAT**: только в шагах `Check auto-review limit` и
  `Request independent review` job запроса (чтение комментариев и `gh pr comment`).
  Остальные шаги и job `review` получают эфемерный `GITHUB_TOKEN`; в `.git/config`
  ревьюера PAT не попадает.
- **Конфиг ревьюера из базовой ветки**: job `review` сначала сохраняет
  `opencode.json` из базовой ветки (`git show origin/<default>:opencode.json`) во
  временный файл, затем запускает действие с `OPENCODE_CONFIG` на этот файл и с
  отключённым обнаружением проектного конфига (`OPENCODE_DISABLE_PROJECT_CONFIG` и
  `OPENCODE_CONFIG_PROJECT_DISABLE`). Поэтому ветка PR не может подменить агента
  `review`, его промпт или права через свой `opencode.json`, `.opencode/` или `.agents/`.
- **Критерии**: `REVIEW.md` в корне репозитория. Job `review` делает checkout с
  `fetch-depth: 0` и читает версию из базовой ветки (`git show origin/<default>:REVIEW.md`),
  чтобы PR не мог подменить критерии. Если файла в базовой ветке нет, ревью
  останавливается с пометкой «не проверено», а версия из PR как критерии не используется.
  Разбор идёт по двум осям: спецификация (`docs/spec.md`, issue, ADR) и стандарты
  (`AGENTS.md`, `REVIEW.md`).
- **До мержа**: пока `opencode-review.yml` есть только в ветке PR, запрос авторевью не
  запустится: `pull_request_target` берёт workflow из базовой ветки. Новая версия
  включается после мержа. Все три jobs слушают только `issue_comment`, поэтому
  `pull_request_review_comment` не запускает ни review-путь, ни ручную job ни до, ни после
  мержа: живой прогон возможен только комментарием `/oc` в обсуждении PR.
- **Формат**: первая строка `> *This was generated by AI during automatic review.*`, затем
  итог, находки с severity, `file:line` и пунктом `REVIEW.md`, отдельно «Проверено» и
  «Не проверено».
- **Права и ограничения**: у job запроса `permissions: {}` и запись только через PAT;
  тайм-аут 5 минут. Job `review` получает `contents: read`, `issues: read`,
  `pull-requests: write`, `checks: read`, `statuses: read` и эфемерный `GITHUB_TOKEN`,
  а не `AGENT_PUSH_TOKEN`; PAT в `.git/config` ревьюера не попадает. Агент `review` в
  `opencode.json` работает только на чтение: `edit`/`write`, суб-агенты, вопросы и внешние
  запросы запрещены, shell ограничен read-only командами `gh`/`git`/`rg`; запись через
  `--output`, `--pre`, `--ext-diff`, `--textconv`, `--filters` и изменяющие формы
  `git branch`/`git remote` запрещены. Он не запускает тесты и скрипты из PR, не одобряет
  и не запрашивает изменения, не меняет метки.
- **Inline-комментарии отключены.** Событие `pull_request_review_comment` убрано из
  триггеров, а job `triage` и `opencode` дополнительно проверяют
  `github.event_name == 'issue_comment'`. Для inline-события GitHub задаёт
  `GITHUB_REF=refs/pull/<N>/merge`, поэтому начальный checkout был бы merge-коммитом PR до
  запуска build-агента с `AGENT_PUSH_TOKEN`. Теперь начальный checkout ручной job — базовая
  ветка. Цена решения: `/oc` в комментарии к строке кода не работает, использовать
  обсуждение PR. Это не defense-in-depth на будущее, а фактическое ограничение триггеров.
- **Тайм-аут и отмена**: запуск job `review` ограничен 20 минутами. При новом коммите
  `concurrency` по номеру PR отменяет устаревшее ревью (`cancel-in-progress: true`);
  ручные `/oc` не отменяются и сохраняют прежний тайм-аут.
- **Шаблон PR**: `.github/pull_request_template.md` требует заполнить проверки, риск и
  способ отката. Авторевью — это комментарий, а не формальное одобрение: решение о мерже
  принимает человек.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
