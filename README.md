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
- **Модель и ключ**: `opencode-go/deepseek-v4.1-flash` (провайдер OpenCode Go), ключ берётся из секрета
  `OPENCODE_API_KEY` (значение хранится в настройках репозитория и в код не попадает).
- **Приватность**: публикация сессии на opencode.ai отключена явно (`share: 'false'`).
- **Безопасность**: у токена только `id-token: write` и `contents: read`, чекаут —
  с `persist-credentials: false`, тайм-аут 15 минут, запуски по одной задаче выполняются
  по очереди (группа `concurrency` по номеру issue/PR).
- **Коммиты агента**: шаг `Configure git identity` выставляет `user.name`/`user.email`
  (`opencode-agent[bot]`); без него `git commit` в раннере падает с `Author identity unknown`.
- **Пуш агента**: шаг `Configure git credentials` прописывает в `.git/config` заголовок
  `AUTHORIZATION` с `AGENT_PUSH_TOKEN`. При `use_github_token: true` сам opencode git-креденшелы
  не настраивает, а чекаут идёт с `persist-credentials: false`, поэтому без этого шага
  `git push` падает с `could not read Username for 'https://github.com'`.
- **Статика воркфлоуов**: `.github/workflows/jactionlint.yml` проверяет файлы Actions
  через jactionlint; та же проверка входит в `mise run check`.

Пример: `/oc объясни, что делает этот репозиторий`.

</details>

## О Хекслете

[Хекслет](https://ru.hexlet.io/) — школа программирования: авторские программы обучения с практикой, поддержкой наставников и реальными проектами, которые остаются в резюме. Этот репозиторий — один из таких проектов.
