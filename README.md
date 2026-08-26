# LDS Revision — Edexcel A Level & AS Level Maths
This is a revision app built using flutter, that aims to help students revise the Edexcel A and AS Level maths large data set. It contains the raw data from the data set itself, as well as past papers and quiz questions for the user to attempt. Moreover, the app has inbuilt progress tracking that is able to tell the user their worst topics, running scores and how many questions they have attempted.

# Data browser
The data browser contails every entry in the Large Data Set - each month (May - October) of each year (1987 and 2015) at each of the 8 weather stations. The data can be filtered by any piece of data, and each full record can be viewed.

# Quiz section
As of release, there are 83 original questions, split into three trypes (MCQ, True or False, and long answer), across 7 differenct topics. The user is able to choose from random, weakest topics, or pick a topic to focus on themselves. The quiz engine also prioritises questions the user got wrong sooner, and reduces the amount of times a question the user keeps getting right is asked. It also include the option of an exam mode, which gives the user 90 seconds per question, and after they finish will give them as score they achieved in timed conditions, but also the score they got from questions they answered outside the timer, if any.

# Past papers
As of release, the app includes each of the A and AS Level past papers available online that include questions on the LDS along with their mark schemes (from 2017 sample paper to June 2024). Each mark scheme and paper can be viewed within the app using an in build PDF viewer. The app does not directly contain the copyrighted papers, but rather links to the offiscial papers. As well as the offiscial mark scheme, there are also marking criteria written by me the user can check. The user is able to enter how many marks they achieved on a question (only the ones on the LDS) and these are save and shown in the progress section. Next to each of the papers, the app tells the user which question is on the LDS.

# Progress tracking
Each quiz answer and past paper attempt is logged. The progress screen will show overall quiz scores, along with the three weakest topics, and seperately will show past paper performance (number attempted and average percentage score)

# Tech stack
Flutter / Dart
Provider - state management
sqflite - local SQLite database (all core data stored on device - no server or backend)
syncfusion_flutter_pdfviewer - in-app PDF rendering for offiscial past papers and mark schemes
url_launcher, shared_preferences, path

# Architecture
lib/
 ├── models/     — plain data classes (LdsRecord, Question, PastPaperQuestion, ProgressEntry)
 ├── data/       — bundled JSON data + the SQLite database layer
 ├── services/   — query logic, scoring, spaced repetition scheduling
 ├── state/      — Provider classes tying services to the UI
 ├── screens/    — one file per screen
 ├── widgets/    — reusable UI components
 ├── theme.dart  — centralised colour palette and styling
 └── main.dart
The LDS was converted from the offiscial .xls spreadsheet using a python script written by AI

# Running it
git clone <your-repo-url>
cd flutter_app_large_data_set
flutter pub get
flutter run

Requires Flutter SDK and android emulator / android device. IOS requires a Mac and has nor been tested as of yet