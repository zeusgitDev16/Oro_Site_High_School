- CODE FLOW:
our main programming language is DART/FLUTTER and our main backend is SUPABASE.
--- Account type - Microsoft account.

UI and interactive flow first. we will not implement any backend logic yet, our goal is to finalize and complete every UI and interactive, and its flow like we can imagine the users flow and activity, once done, that is the only time we will implement a backend, and do not implement a backend without my request. do not assume anything and strictly stick to what i have just prompted.

UI code is separated from its interactive logic.
    example of this is let us say we have a button, that button's UI code has it's own class and the interactive logic is in another class. to put it simply imagine the button in the admin dashboard and you can see the interactiveness of it is referenced.

BACKEND & RESPONSIVE DESIGN LOGIC is also separated.

to summarize, here is the four code logic that we should ensure that is separated.
UI > INTERACTIVE LOGIC > BACKEND > RESPONSIVE DESIGN LOGIC.

- RULES
1. once we finished something, avoid modifying it unless i said so.
2. avoid making the file too big that is why we separate certain logic in the first place.
3. do not modify any code logic that is out of my request, if i request something, strictly stick to that and do not change anything outside context.

- USER TYPE and THEIR EXPECTED EXPERIENCE:
  
  ADMIN - admin role is the core user that manages everything in the system, these is typically the principal of the school & ICT coordinators.

  Teacher -  there are two types in this, the GRADE LEVEL COORDINATOR and the normal teacher, the grade level coordinator has control and can manage all sections of that specific grade, for example grade 7, so as their GRADE LEVEL COORDINATOR, i should be able to manage all students in grade 7 like i can reset their account password, i can also track and see their progress, and i can also manage their attendance, i can also manage their grades, i can also manage their assignments, i can also manage their resources, i can also manage their messages, i can also manage their notifications, i can also manage their reports, i can also manage their users, i can also manage their roles, i can also manage their permissions, i can also manage their system settings, i can also manage their analytics, i can also manage their courses, i can also manage their organizations, i can also manage their groups, i can also manage their surveys.

  to put it simply, the teacher can manage their advised section (example: grade 7 diamond), and the grade level coordinator can do the same but to the whole sections in a specific grade level(example: grade 7 amethyst, grade 7 bronze, grade 7 copper, etc.)
  and we have a total of 6 grade level coordinator accounts which grade 7 to grade 12.

  STUDENT - these users can access learning materials, learning resources, assignments, messages, notifications, reports, and other related information. they can also access their personal profile and settings. also they can see their progress, attendance and grades.

  PARENT - this user should be simple, the sole purpose of this is to just track their children's progress, time in and time out in the school, their children's attendance and most importantly, their children's grades.

  HYBRID USER - a HYBRID USER TYPE is a mix one, so in ORO SITE HIGHSCHOOL ICT coordinator do also teach students so they should be able to have the same features as a teacher but, this should be switch like there are ICT coordinators that do not teach and ICT coordinators that do teach so we will implement a switch button in the settings of the admin i guess? that we can enable hybrid user types to a certain user.



---  ATTENDANCE MANAGEMENT SYSTEM:
   - so my coleague is creating a attendance management system that has a scanner feature that will scan the barcode in the back of the students id card and it will automatically update the attendance status in the system. this system is a sub system meaning it is out of this file. our system that we are working on is ELMS and my partner is coding the subsystem which is the attendance management system, so our job is to just implement a fetching system that we can connect to my partner's work and save data for the attendance like, when the scanner scans in that subsystem, the data will be saved in our system like the time, date, student LRN, and attendance status.

   so the flow of this is that, the teacher has only the rights to scan, the flow of this is like let us say i am a teacher, and i have a schedule like 7:00am to 9:00 am, in my system i will create a new attendance, and i will give the details like the day if its monday, tuesday, wednesday, thursday, friday, saturday, sunday, and also pick the schedule like 7:00am to 9:00am, and i can set a time limit to the scanner like 15 minutes, within 15 minutes all student must be scanned before the timer expires, when that expires, all late comers will be marked as late. so our system also need to save this data and export it in excel format and is already finished like the exported excel should display the students absents, lates, and the attendance status in general. like for the past weeks and months.

   also teachers can grant students a permission if they can scan, this feature will also help to promote efficiency. but by default, students does not have rights to scan, they can scan only if they are permitted.


  --- REPORTS AND ARCHIVING:
   - we should be able to save reports and archives in our system too like s.y 2025, s.y 2024 etc. and also the data of the students like all of it, like we should be able to save and archive all data in our system.



