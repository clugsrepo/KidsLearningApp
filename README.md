# KidsLearningApp

Printable A4 practice sheets for the kids, at https://clugsrepo.github.io/KidsLearningApp/

Use the **Spellings / Maths / Tens & ones** switch at the top to move between the pages. Settings are remembered in the browser for next time. Nothing is sent anywhere.

## Spelling Sheets (`index.html`)

Type the week's words (one per line), check the preview and press **Print**.

### Sheet types

- **Practice lines**: each word written at the top with lines underneath to copy it, 1 to 4 words per page.
- **Look, cover, write, check**: fold along the dashed line to hide the words, write from memory, then tick.
- **Spelling test**: numbered lines plus name, date and score, for reading the words out at the end of the week.

### Options

- Line size: big, medium or small.
- Plain lines, or handwriting guides (top line, dashed middle line, baseline).
- School print letters (single-storey a and g) or a handwritten style.
- Trace the word first: a pale copy of the word on the first line to write over.

## Maths Sheets (`maths.html`)

Two sums per page, each with a box for the answer and space underneath to work it out.

- **Sums**: adding, taking away, or both.
- **Number sizes**: tens, hundreds and thousands (like 47, 382 and 5164). Tick more than one to mix them.
- **Include exchanging**: every sum needs carrying or borrowing. Untick it for easier sums with none.
- **Working-out space**: big (1 cm) squares, small (7 mm) squares, or blank. Place value headings (TTh, Th, H, T, O) can sit along the top of the squares.
- **Answers**: printed after the sums. **With workings** shows each sum done in columns (carries and exchanges marked) with a step for each column, starting from the ones. **Answers only** is a single list. Or **None**.
- **Fresh sums every time**: a new set each time the page opens, each time you press Print, and when you come back to the page after half an hour. **New sums** swaps the set straight away. The answers always match the sums they print with.

## Tens and Ones (`tens-and-ones.html`)

Year 2 place value: four mixed questions per page, with a key showing a stick of ten cubes is 1 ten and a single cube is 1 one.

- **Count the picture**: count the tens sticks and ones cubes, then write the number.
- **Part-whole**: split a number into tens and ones in the part-whole circles, or find the whole from its parts.
- **Draw it**: draw a number as tens and ones.
- **Fill the gaps**: sentences like `[ ] = 40 + 2`, `3 tens and 2 ones = [ ]` and `[ ] tens and [ ] ones = 17`, labelled a to d.
- **Numbers**: up to 20, 50 or 100. **Pages**: 1 to 5, plus an answers page.
- A fresh set each time the page opens or you press Print, like the maths page.

## How it's built

Plain HTML, CSS and JavaScript with no build step. `app.css` and `sheet-app.js` hold the shared look, saved settings, preview, printing and the fresh-every-time question seed; each page adds its own sheet layouts. Sheets are laid out in millimetres so the printout matches the preview.

## Printing tips

Choose A4 paper. If a sheet spills onto a second page, set margins to **None** (or Default) in the print box.
