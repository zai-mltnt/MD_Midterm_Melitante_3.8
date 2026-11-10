# Community Learning Center Management System

**Student Name:** Melitante, Joezainne Q.

**Section:** 3.8 BSIT 

**Course/Examination:** Mobile Development – Midterm Laboratory Examination

## Project Description

The Community Learning Center Management System is an integrated Dart console application for registering learning resources and participants, processing borrow/return transactions, displaying records, and searching by identification number. It follows the supplied Mobile Development Midterm Laboratory Examination specification and is implemented as one console program in `main.dart` (not Flutter).

> **Data storage note:** Records are kept in memory using Dart Lists and Maps while the program is running. They are not saved to a database or file; closing the program clears the session's records.

## Features

- Register learning resources with ID, title, category, copy quantity, and replacement cost.
- Register participants with ID, full name, and section/group.
- View resources, participants, all records, and transaction history.
- Borrow available copies and create a transaction ID.
- Return a resource using its transaction ID.
- Search resource and participant records by ID.
- Prevent duplicate resource and participant IDs.
- Reject nonexistent IDs and unavailable resources during borrowing.
- Prevent a transaction from being returned more than once.
- Validate empty input, positive quantities, numeric costs, and menu choices.
- Keep the menu running until the user chooses Exit.

## Technologies Used

- Dart SDK (console application)
- Visual Studio Code
- Dart extension for Visual Studio Code
- Windows 10 (development environment)

## Dart Concepts Demonstrated

- **Fundamentals:** `String`, `int`, `double`, `bool`, inferred variables, console I/O, arithmetic and comparison operators.
- **Control structures:** `if/else`, `switch`, `while`, and `for` loops.
- **Functions:** Multiple user-defined functions with parameters and actions.
- **Error handling:** `try-catch`, `FormatException`, and validation messages.
- **OOP:** constructors, objects, methods, private fields (`_id`, `_name`, `_availableCopies`, etc.), getters and a setter.
- **Collections:** Lists store the ordered resource, participant, and transaction records; Maps provide ID-based lookup.
- **Abstraction and inheritance:** abstract `CenterRecord` parent class; `LearningResource` and `Participant` subclasses.
- **Overriding and polymorphism:** both subclasses override `recordType` and `displayDetails`; the system displays both through `List<CenterRecord>`.
- **Mixin:** `Timestamped` provides reusable creation-time behavior to records and transactions.

## Project Structure

```text
CommunityLearningCenter/
├── main.dart
├── README.md
```

## Requirements

- Windows 10 or later
- Dart SDK installed and available in the Windows `PATH`
- Visual Studio Code
- Dart extension installed in VS Code

Check the SDK in the VS Code terminal:

```powershell
dart --version
```

## How to Run in Visual Studio Code

1. Open Visual Studio Code.
2. Select **File → Open Folder** and open `CommunityLearningCenter`.
3. Open the integrated terminal using **Terminal → New Terminal**.
4. Confirm Dart is available with `dart --version`.
5. Run the program:

   ```powershell
   dart run main.dart
   ```

   You can also use `dart main.dart`.
6. Follow the numbered menu. Enter `0` to exit.

To check the source for static issues, run:

```powershell
dart analyze main.dart
```

## Sample Testing Scenarios

Perform these tests in a fresh program session unless a scenario says otherwise. The expected messages below describe the intended behavior; capture your own actual terminal output as evidence.

### Test 1 – Successful resource registration

1. Run `dart run main.dart`.
2. Choose `1`.
3. Enter resource ID `BK001`, title `Introduction to Programming`, category `Book`, copies `3`, and cost `450.00`.
4. Choose `3` to view resources.

**Expected:** A successful registration message appears. `BK001` is listed with 3 available copies out of 3.

### Test 2 – Successful participant registration

1. Choose `2`.
2. Enter participant ID `P001`, name `Alex Student`, and section/group `BSIT 1A`.
3. Choose `4`.

**Expected:** A successful registration message appears and participant `P001` is displayed.

### Test 3 – Successful borrowing and returning

1. First register `BK001` with one or more copies and `P001` as a participant.
2. Choose `5`; enter resource ID `BK001` and participant ID `P001`.
3. Record the transaction ID shown (for example, `TX0001`).
4. Choose `3` and confirm available copies decreased by one.
5. Choose `6`; enter the transaction ID.
6. Choose `3` again and then `7`.

**Expected:** Borrowing succeeds and an ID is generated. Available quantity decreases by one. Returning succeeds, available quantity increases by one, and the transaction history shows `RETURNED`.

### Test 4 – Invalid menu input

1. At the main menu, enter `abc` or `15`.

**Expected:** The program displays an invalid menu choice message and shows the menu again instead of terminating.

### Test 5 – Nonexistent or unavailable resource

1. Choose `5` and enter a resource ID that was never registered, such as `NO-SUCH-ID`, with a valid participant ID.
2. For the unavailable case, register a resource with one copy, borrow that copy, and attempt to borrow it again before returning it.

**Expected:** A nonexistent ID is rejected with a helpful message. A second borrow when no copies remain is rejected; the quantity must not become negative and no extra transaction is created.

### Additional useful checks

- Register the same resource ID twice: the duplicate must be rejected.
- Register the same participant ID twice: the duplicate must be rejected.
- Return a transaction, then try to return it again: the second return must be rejected.
- Search using a valid and an unknown resource/participant ID.
- Enter a non-numeric quantity or replacement cost and confirm validation.

## Capturing Actual Test Evidence

1. Run the application in the VS Code integrated terminal.
2. Reproduce each scenario using real keyboard input.
3. Capture screenshots showing the input, resulting message, and relevant updated record/quantity. On Windows, use **Win + Shift + S** and save the screenshot.
4. Use clear filenames such as `test1-resource-registration.png`, `test3-borrow-return.png`, and `test4-invalid-menu.png`.
5. Do not edit screenshots to make a failed test look successful. If a test fails, correct the code, rerun it, and capture the actual result.

## Troubleshooting

| Problem | What to do |
|---|---|
| `dart` is not recognized | Confirm the Dart SDK `bin` folder is in the Windows `PATH`; restart VS Code and open a new terminal. |
| `dart: command not found` | Check SDK installation and `PATH` using `dart --version`. |
| Wrong folder opened | Open the folder containing `main.dart`, then run the command in that folder. |
| Program reports invalid input | Follow the prompt's expected type; quantities must be positive whole numbers and cost must be numeric. |
| Borrowing fails | Confirm both IDs exist and the resource has at least one available copy. |
| Return fails | Check that the transaction ID exists and is still marked `BORROWED`. |
| Records disappear after exit | This version stores data in memory only; persistence is outside the examination's stated minimum requirements. |

## GitHub Submission

The examination asks for one accessible repository named `MD_Midterm_[Surname]_[Section]` containing `main.dart` and `README.md`.

1. Create a GitHub repository using the required naming pattern.
2. Add `main.dart`, `README.md`, and optionally `.gitignore`.
3. Commit and push the final version.
4. Set repository visibility to Public or provide the instructor access, as required by the exam.
5. Open the repository link in a browser to verify that the files are accessible before submitting it.

## AI Use Declaration

AI assistance was used to help interpret the laboratory examination requirements, plan the class structure, draft and explain Dart code, prepare documentation, and develop testing scenarios..

---

**Important:** The program's actual execution and analysis must be verified on a computer with the Dart SDK. 
