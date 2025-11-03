### here are my answers to your questions:

1. do i want to support multiple grading periods? ---> yes
2. Should the system calculate final grades? ---> yes
3. do i need remedial/recomputation tracking for failed students? ---> yes
4. should we implement Transmutation tables? ---> yes
5. passing grade is yes the usual 75 dep ed.

1. what is the current school year format? ---> 2025 - 2026
2. do you follow the standard deped callendar with quarters? ---> yes but make this adjustable cause sometimes, it change depends on the situation.
3. do I need automatic school year rollover? ---> absolutely yes

1. confirms grade levels: yes you are correct, 7 to 12 (we will include SHS system too like the subject is given based on the strand right? so we should have a DEPED system style of how they manage SHS students and the courses for the SHS students)
2. how many sections per grade level? --> currently and honestly, i do not know, but how about you make this robust and flexible that we can just add sections as needed per grade level? 
3. do you use stand-based sections? --> yes and this part is crucial cause the SHS part is a little bit complex
4. should sections names follow a pattern? ---> could be, let's make this additional feature.

1. how do i want to create accounts? ---> well honestly, i want to create an account directly into the system like in the admin, admin has the authority to create an account, since deped has free microsoft accounts for students, what i have in mind is that we can just connect the account in the system i guess? honestly as a human with no prior experience i do not know, so i think in this part i will let you suggest too, on what is the best implementation here? should we add a feature in the system that the admin can create microsoft accounts directly in the system and it will be saved in the azure portal? or we manually add the microsoft accounts in the azure portal? honestly, i don't know, so i will count to your suggestion about here too. also, bulk via excel or manual? why not both? i think both is the great choice!
2. should students be auto enrolled wen added in a section? ---> yes
3. do i need LRN validation? ---> lets make this optional
4. should the system generate default passwords for new users? ---> yes

1. do you follow the standard deped curriculum? ---> yes
2. should courses be pre-loaded based on grade level? ---> yes
3. can one course have multiple teachers? ---> let's make this optional like situational
4. do you need subject code tracking? ---> yes i think this will be good for organized tracking.

1. is my colleague's scanner sub system already deployed? ---> not yet
2. what is the database table structure they're using for scan data? ---> do not have any information about this yet
3. do you have api endpoints or is it direct database access? ---> i do have API endpoints
4. should attendance affect grade computation? ---> let's make this optional and situational too.

1. what excel reports formats do you need? ---> SF9
2. Should reports include school letterhead/logo? ---> optional
3. do you need difital signatures on reports? ---> optional
4. should reports be printable? ---> yes

1. how do parents get linked to students? ---> my thoughts on this is parents can create an account by their google account or facebook account and then the admin links their child's LRN to their account and once linked, the parent can now see their child's progress as well as track their children's attendance and all features included in the parent dashboard.
2. should parents recieve automatics notifications for low grades, absences and new assignements? ---> yes
3. do you want sms notifications? ---> no, notification from the parent dashboard should be enough, as sms notifications can be complex and budget draining.

1. should grade coordinators have the ability to: override? reset and generate reports for entire grade? ---> yes
2. can regular teachers see other teacher classes? ---> sure but they can't access, only the grade coordinator can, but regular teachers can see other classes but it is read only. 
3. Should there be audit logs for sensitive actions (grade changes, password resets)? ---> yes

1. Do you have existing student data to import? ---> no
2. Do you need to migrate from an old system? ---> no
3. Should we create sample/test data for development? ---> depends on what's best
4. Do you want demo accounts for each user type? ---> i already have one, i created demo accounts in my azure portal but currently the parent user does not have yet because like i said, what i have in mind for parents is google or facebook account.


