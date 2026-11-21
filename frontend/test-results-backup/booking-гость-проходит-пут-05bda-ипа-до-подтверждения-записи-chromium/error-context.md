# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: booking.spec.ts >> гость проходит путь от выбора типа до подтверждения записи
- Location: e2e\booking.spec.ts:92:1

# Error details

```
Error: expect(locator).toContainText(expected) failed

Locator: locator('.admin-table tbody tr').filter({ hasText: '2026-11-15' })
Expected substring: "10:30"
Error: strict mode violation: locator('.admin-table tbody tr').filter({ hasText: '2026-11-15' }) resolved to 4 elements:
    1) <tr>…</tr> aka getByRole('row', { name: '2026-11-15 09:00 – 09:30' })
    2) <tr>…</tr> aka getByRole('row', { name: '2026-11-15 09:30 – 10:00' })
    3) <tr>…</tr> aka getByRole('row', { name: '2026-11-15 10:00 – 10:30' })
    4) <tr>…</tr> aka getByRole('row', { name: '2026-11-15 10:30 – 11:00' })

Call log:
  - Expect "toContainText" locator('.admin-table tbody tr').filter({ hasText: '2026-11-15' }) with timeout 10000ms
  - waiting for locator('.admin-table tbody tr').filter({ hasText: '2026-11-15' })

```

# Page snapshot

```yaml
- generic [ref=f2e3]:
    - banner [ref=f2e4]:
        - link "Calendar" [ref=f2e5] [cursor=pointer]:
            - /url: /
        - navigation [ref=f2e13]:
            - link "Записаться" [ref=f2e14] [cursor=pointer]:
                - /url: /booking
            - link "Админка" [ref=f2e15] [cursor=pointer]:
                - /url: /admin
    - main [ref=f2e16]:
        - generic [ref=f2e17]:
            - generic [ref=f2e18]: Гость
            - heading "Админка" [level=1] [ref=f2e20]
            - paragraph [ref=f2e21]: Владелец календаря управляет типами встреч и просматривает записи.
            - generic [ref=f2e22]:
                - heading "Типы встреч" [level=2] [ref=f2e23]
                - generic [ref=f2e24]:
                    - generic [ref=f2e25]:
                        - text: Название
                        - textbox "Название" [ref=f2e26]
                    - generic [ref=f2e27]:
                        - text: Описание
                        - textbox "Описание" [ref=f2e28]
                    - generic [ref=f2e29]:
                        - text: Длительность, мин
                        - spinbutton "Длительность, мин" [ref=f2e30]: '30'
                    - button "Добавить тип" [ref=f2e32] [cursor=pointer]
                - list [ref=f2e33]:
                    - listitem [ref=f2e34]:
                        - generic [ref=f2e35]: Встреча 15 минут
                        - generic [ref=f2e36]: — Короткий тип события для быстрого слота
                        - generic [ref=f2e37]: (15 мин)
                        - generic [ref=f2e38]:
                            - button "Редактировать" [ref=f2e39] [cursor=pointer]
                            - button "Удалить" [ref=f2e40] [cursor=pointer]
                    - listitem [ref=f2e41]:
                        - generic [ref=f2e42]: Встреча 30 минут
                        - generic [ref=f2e43]: — Базовый тип события для бронирования
                        - generic [ref=f2e44]: (30 мин)
                        - generic [ref=f2e45]:
                            - button "Редактировать" [ref=f2e46] [cursor=pointer]
                            - button "Удалить" [ref=f2e47] [cursor=pointer]
            - generic [ref=f2e48]:
                - heading "Предстоящие записи" [level=2] [ref=f2e49]
                - table [ref=f2e50]:
                    - rowgroup [ref=f2e51]:
                        - row [ref=f2e52]:
                            - columnheader "Дата" [ref=f2e53]
                            - columnheader "Время" [ref=f2e54]
                            - columnheader "Гость" [ref=f2e55]
                            - columnheader "Тип встречи" [ref=f2e56]
                    - rowgroup [ref=f2e57]:
                        - row [ref=f2e58]:
                            - cell "2026-11-15" [ref=f2e59]
                            - cell "09:00 – 09:30" [ref=f2e60]
                            - cell "Гость🦊" [ref=f2e61]
                            - cell "Встреча 30 минут" [ref=f2e62]
                        - row [ref=f2e63]:
                            - cell "2026-11-15" [ref=f2e64]
                            - cell "09:30 – 10:00" [ref=f2e65]
                            - cell "Гость🦊" [ref=f2e66]
                            - cell "Встреча 30 минут" [ref=f2e67]
                        - row [ref=f2e68]:
                            - cell "2026-11-15" [ref=f2e69]
                            - cell "10:00 – 10:30" [ref=f2e70]
                            - cell "Гость🦊" [ref=f2e71]
                            - cell "Встреча 30 минут" [ref=f2e72]
                        - row [ref=f2e73]:
                            - cell "2026-11-15" [ref=f2e74]
                            - cell "10:30 – 11:00" [ref=f2e75]
                            - cell "Гость🦊" [ref=f2e76]
                            - cell "Встреча 30 минут" [ref=f2e77]
                        - row [ref=f2e78]:
                            - cell "2026-11-16" [ref=f2e79]
                            - cell "09:00 – 09:30" [ref=f2e80]
                            - cell "Гость🦊" [ref=f2e81]
                            - cell "Встреча 30 минут" [ref=f2e82]
                        - row [ref=f2e83]:
                            - cell "2026-11-16" [ref=f2e84]
                            - cell "09:30 – 10:00" [ref=f2e85]
                            - cell "Гость🦊" [ref=f2e86]
                            - cell "Встреча 30 минут" [ref=f2e87]
                        - row [ref=f2e88]:
                            - cell "2026-11-16" [ref=f2e89]
                            - cell "10:00 – 10:30" [ref=f2e90]
                            - cell "Гость🦊" [ref=f2e91]
                            - cell "Встреча 30 минут" [ref=f2e92]
                        - row [ref=f2e93]:
                            - cell "2026-11-17" [ref=f2e94]
                            - cell "09:00 – 09:30" [ref=f2e95]
                            - cell "Гость🦊" [ref=f2e96]
                            - cell "Встреча 30 минут" [ref=f2e97]
                        - row [ref=f2e98]:
                            - cell "2026-11-17" [ref=f2e99]
                            - cell "09:30 – 10:00" [ref=f2e100]
                            - cell "Гость🦊" [ref=f2e101]
                            - cell "Встреча 30 минут" [ref=f2e102]
                        - row [ref=f2e103]:
                            - cell "2026-11-17" [ref=f2e104]
                            - cell "10:00 – 10:30" [ref=f2e105]
                            - cell "Гость🦊" [ref=f2e106]
                            - cell "Встреча 30 минут" [ref=f2e107]
    - contentinfo [ref=f2e108]: Calendar · учебный проект Хекслета
```

# Test source

```ts
  7   | const MONTHS = [
  8   |   'январь',
  9   |   'февраль',
  10  |   'март',
  11  |   'апрель',
  12  |   'май',
  13  |   'июнь',
  14  |   'июль',
  15  |   'август',
  16  |   'сентябрь',
  17  |   'октябрь',
  18  |   'ноябрь',
  19  |   'декабрь',
  20  | ];
  21  |
  22  | interface TargetDate {
  23  |   iso: string;
  24  |   day: number;
  25  |   monthIndex: number;
  26  |   year: number;
  27  | }
  28  |
  29  | /** Дата в часовом поясе владельца: окно записи считается от неё. */
  30  | function almatyDate(offsetDays: number): TargetDate {
  31  |   const moment = new Date(Date.now() + offsetDays * 24 * 60 * 60 * 1000);
  32  |   const iso = new Intl.DateTimeFormat('en-CA', {
  33  |     timeZone: 'Asia/Almaty',
  34  |     year: 'numeric',
  35  |     month: '2-digit',
  36  |     day: '2-digit',
  37  |   }).format(moment);
  38  |   const [year, month, day] = iso.split('-').map(Number);
  39  |   return { iso, day, monthIndex: month - 1, year };
  40  | }
  41  |
  42  | async function openBooking(page: Page, typeId: string): Promise<void> {
  43  |   await page.goto(`/booking/${typeId}`);
  44  |   await expect(page.locator('.calendar-grid')).toBeVisible();
  45  | }
  46  |
  47  | /** Листает календарь до нужного месяца и выбирает дату, дожидаясь слотов. */
  48  | async function selectDate(page: Page, date: TargetDate): Promise<void> {
  49  |   for (let attempt = 0; attempt < 3; attempt += 1) {
  50  |     const label = (await page.locator('.month-label').innerText()).trim();
  51  |     const [monthName, yearPart] = label.split(' ');
  52  |     const viewMonth = MONTHS.indexOf(monthName.toLowerCase());
  53  |     const viewYear = Number(yearPart);
  54  |     const delta = (date.year - viewYear) * 12 + (date.monthIndex - viewMonth);
  55  |     if (delta === 0) break;
  56  |     const navigation = delta > 0 ? 'Следующий месяц' : 'Предыдущий месяц';
  57  |     await page.getByRole('button', { name: navigation }).click();
  58  |     await expect(page.locator('.month-label')).not.toHaveText(label);
  59  |   }
  60  |
  61  |   await expect(page.locator('.month-label')).toHaveText(
  62  |     `${MONTHS[date.monthIndex]} ${date.year} г.`,
  63  |   );
  64  |
  65  |   const slotsResponse = page.waitForResponse(
  66  |     (response) =>
  67  |       response.url().includes('/api/slots') && response.url().includes(`date=${date.iso}`),
  68  |   );
  69  |   await page
  70  |     .locator('.calendar-grid')
  71  |     .getByRole('button', { name: String(date.day), exact: true })
  72  |     .click();
  73  |   await slotsResponse;
  74  |   await expect(page.locator('.slots .slot').first()).toBeVisible();
  75  | }
  76  |
  77  | /** Нажимает первый свободный слот и возвращает время его начала. */
  78  | async function selectFirstFreeSlot(page: Page): Promise<string> {
  79  |   const slot = page.locator('.slots .slot:not(.slot-busy)').first();
  80  |   await expect(slot).toBeVisible();
  81  |   const range = (await slot.locator('span').first().innerText()).trim();
  82  |   await slot.click();
  83  |   await expect(slot).toHaveClass(/slot-selected/);
  84  |   return range.split(/\s*–\s*/)[0];
  85  | }
  86  |
  87  | async function confirmBooking(page: Page): Promise<void> {
  88  |   await page.getByRole('button', { name: 'Продолжить' }).click();
  89  |   await expect(page.locator('.success-modal')).toContainText('Вы успешно записаны');
  90  | }
  91  |
  92  | test('гость проходит путь от выбора типа до подтверждения записи', async ({ page }) => {
  93  |   const date = almatyDate(1);
  94  |
  95  |   await page.goto('/booking');
  96  |   await page.locator('.meeting-type', { hasText: MEETING_30.name }).click();
  97  |   await expect(page).toHaveURL(/\/booking\/meeting-30$/);
  98  |
  99  |   await selectDate(page, date);
  100 |   const startTime = await selectFirstFreeSlot(page);
  101 |   await confirmBooking(page);
  102 |
  103 |   // Владелец видит предстоящую встречу в админке.
  104 |   await page.goto('/admin');
  105 |   await expect(page.locator('.admin-table')).toBeVisible();
  106 |   const row = page.locator('.admin-table tbody tr', { hasText: date.iso });
> 107 |   await expect(row).toContainText(startTime);
      |                     ^ Error: expect(locator).toContainText(expected) failed
  108 |   await expect(row).toContainText(MEETING_30.name);
  109 | });
  110 |
  111 | test('при конфликте гость видит понятное сообщение о занятом слоте', async ({ context }) => {
  112 |   const date = almatyDate(2);
  113 |   const firstGuest = await context.newPage();
  114 |   const secondGuest = await context.newPage();
  115 |
  116 |   await openBooking(firstGuest, MEETING_30.id);
  117 |   await selectDate(firstGuest, date);
  118 |   const firstSlot = await selectFirstFreeSlot(firstGuest);
  119 |
  120 |   // Второй гость открывает тот же слот до того, как первый его занял.
  121 |   await openBooking(secondGuest, MEETING_30.id);
  122 |   await selectDate(secondGuest, date);
  123 |   const secondSlot = await selectFirstFreeSlot(secondGuest);
  124 |   expect(secondSlot).toBe(firstSlot);
  125 |
  126 |   await confirmBooking(firstGuest);
  127 |
  128 |   await secondGuest.getByRole('button', { name: 'Продолжить' }).click();
  129 |   await expect(secondGuest.locator('.hint-error')).toHaveText(
  130 |     'Это время уже занято. Выберите другой слот.',
  131 |   );
  132 | });
  133 |
  134 | test('занятый слот не предлагается как свободный и не бронируется другим типом', async ({
  135 |   page,
  136 |   request,
  137 | }) => {
  138 |   const date = almatyDate(3);
  139 |
  140 |   await openBooking(page, MEETING_30.id);
  141 |   await selectDate(page, date);
  142 |   const startTime = await selectFirstFreeSlot(page);
  143 |   await confirmBooking(page);
  144 |
  145 |   // После записи слот того же типа помечен занятым и недоступен для клика.
  146 |   await openBooking(page, MEETING_30.id);
  147 |   await selectDate(page, date);
  148 |   const busy = page.locator('.slot-busy', { hasText: startTime }).first();
  149 |   await expect(busy).toBeDisabled();
  150 |   await expect(busy).toContainText('Занято');
  151 |
  152 |   // Для другого типа встречи пересекающийся старт тоже занят.
  153 |   await openBooking(page, MEETING_15.id);
  154 |   await selectDate(page, date);
  155 |   await expect(page.locator('.slot-busy', { hasText: startTime }).first()).toBeDisabled();
  156 |
  157 |   // Повторная запись на это время через настоящий API отклоняется.
  158 |   const conflict = await request.post('/api/bookings', {
  159 |     data: {
  160 |       meetingTypeId: MEETING_15.id,
  161 |       date: date.iso,
  162 |       startTime,
  163 |       guestName: 'Гость E2E',
  164 |       guestAvatar: '🦊',
  165 |     },
  166 |   });
  167 |   expect(conflict.status()).toBe(409);
  168 |   expect((await conflict.json()).detail).toContain('Слот уже занят');
  169 | });
  170 |
```
