vcproj2cmake.rb - .vcproj to CMakeLists.txt converter scripts
written by Jesper Eskilson and Andreas Mohr.
FIXME licensing (BSD)

----------
DISCLAIMER: there are NO WARRANTIES as to the suitability of this converter,
thus make sure to have suitable backup; if things break,
then you certainly get to keep both parts.
----------


vcproj2cmake has been fully tested with CMake 2.6.x only - while some 2.8.x testing has been done,
there may be some rough spots.


Usage (very rough summary), with Linux/Makefile generator:
- use existing Visual Studio project source tree which contains a .vcproj file
- in the project source tree, run ruby [PATH_TO_VCPROJ2CMAKE]/scripts/vcproj2cmake.rb PROJECT.vcproj
  (alternatively, execute vcproj2cmake_recursive.rb to convert an entire hierarchy of .vcproj sub projects)
- copy all required cmake/Modules, cmake/vcproj2cmake and samples (provided by the vcproj2cmake source tree!)
  to their respective paths in your project source tree
- after successfully converting the .vcproj file to a CMakeLists.txt, start your out-of-tree CMake builds:
  - mkdir ../[PROJECT_NAME].build_toolkit1_v1.2.3_unicode_debug
  - cd ../[PROJECT_NAME].build_toolkit1_v1.2.3_unicode_debug
  - cmake -DCMAKE_BUILD_TYPE=Debug ../[PROJECT_NAME] (alternatively: ccmake ../[PROJECT_NAME])
  - time make -j3 -k


NOTE: first thing to state is:
if you do not have any users who are hooked on keep using
their static .vcproj files on Visual Studio, then it perhaps makes less sense
to use our converter as a somewhat more cumbersome _online converter_ solution
- instead you may choose to go for a full-scale manual conversion
to CMakeLists.txt files (by basing your initial CMakeLists.txt layout
on the output of our script, too, of course).
That way you can avoid having to deal with the hook script includes as
required by our online conversion concept, and instead modify your
CMakeLists.txt files directly wherever needed (since _they_ will be your
authoritative project information in future on all platforms, instead of the static .vcproj files).

OTOH by using our scripts for one-time-conversion only, you will lose out
on any of the hopefully substantial improvements done to our
online conversion script in the future
(such as automagically provided installation/packaging configuration mechanisms, ...),
thus it's a tough initial decision to make on whether to maintain an online conversion
infrastructure or to go initial-convert only and thus run _all_ sides on a CMake-based
setup.



===============================================================================
Explanation of core concepts:


=== Hook script includes ===

In the generated CMakeLists.txt file(s), you may notice lines like
include(${V2C_HOOK_PROJECT} OPTIONAL)
These are meant to provide interception points ("hooks") to enhance online-converted
CMakeLists.txt with specific static content (e.g. to call required CMake Find scripts
via "find_package(Foobar REQUIRED)",
or to override some undesireable .vcproj choices, to provide some user-facing
CMake setup cache variables, etc.).
One could just as easily have written this line like
include(cmake/vcproj2cmake/hook_project.txt OPTIONAL)
, but then it would be somewhat less flexible (some environments might want to
temporarily disable use of these included scripts, by changing the variable
to a different/inexistent script).
Note that these required variables like V2C_HOOK_PROJECT are pre-defined by our
vcproj2cmake_defs.cmake module.


Example hook scripts to be used by every sub project in your project hierarchy that needs
such customizations are provided in our repository's sample/ directory.


=== mappings files (definitions, dependencies, library directories, include directories) ===

Certain compiler defines in your projects may be Win32-only,
and certain other defines might need a different replacement on a certain other platform.

Dito with library dependencies, and especially with include and library directories.

This is what vcproj2cmake's mappings file mechanism is meant to solve
(see cmake/vcproj2cmake/include_mappings.txt etc.).


Basic syntax of mappings files is:

Original expression as used by the static Windows side (.vcproj content)
- note case sensitivity! -,
then ':' as separator between original content and CMake-side mappings,
then a platform-specific identifier (WIN32, APPLE, ...) which is used
  in a CMake "if(...)" conditional (or no identifier in case the mapping
  is supposed to be platform-universal),
then a '=' to assign the replacement expression to be used on that platform,
then the ensuing replacement expression.
Then an '|' (pipe, "or") for an optional series of additional platform conditionals.


Note that ideally you merely need to centrally maintain all mappings in your root project part
(ROOT_PROJECT/cmake/vcproj2cmake/*_mappings.txt), since sub projects will also
collect information from the root project in addition to their (optional) local mappings files.


=== Miscellaneous ===

vcproj2cmake_recursive.rb supports skipping of certain unwanted sub projects
(e.g. ones that are very cross-platform incompatible) within your
Visual Studio project tree.
This is to be done by mentioning the names of the projects to be excluded
in the file $v2c_config_dir_local/project_exclude_list.txt


=== Automatic re-conversion upon .vcproj changes ===

vcproj2cmake now contains a mechanism for _automatically_ triggered re-conversion of files
whenever the backing .vcproj file received some updates.
This is implemented in function
cmake/Modules/vcproj2cmake_func.cmake/v2c_rebuild_on_update()
This internal mechanism is enabled by default, you may modify the CMake cache variable
V2C_USE_AUTOMATIC_CMAKELISTS_REBUILDER to disable it.
NOTE: in order to have the automatic re-conversion mechanism work properly,
this currently needs the initial (manual) converter invocation
to be done from root project, _not_ any other directory (FIXME get rid of this limitation).

Since the converter will be re-executed from within the generated files (Makefile etc.),
it will convert the CMakeLists.txt that these are based on _within_ this same process.
However, it has no means to abort subsequent target execution once it notices that there
were .vcproj changes which render the current CMake generator build files obsolete.
Thus, the current build instance will run to its end, and it's important to then launch
it a second time to have CMake start a new configure run with the CMakeLists.txt and
then re-build all newly modified targets.
There's no appreciable way to immediately re-build the updated configuration -
see CMake list "User-accessible hook on internal cmake_check_build_system target?".

To cleanly re-convert all CMakeLists.txt in an isolated way after a source upgrade via SCM,
you may invoke target update_cmakelists_ALL, followed by doing a full build.


=== Troubleshooting ===

- use CMake's message(FATAL_ERROR "DBG: xxx") command
- add_custom_command(... COMMENT="DBG: we are doing ${THIS} and failing ${THAT}")
- cmake --debug-output --trace

If there's compile failure due to missing includes, then this probably means that
the newly converted CMakeLists.txt still contains an include_directories() command
which lists some paths in their raw, original, Windows-specific form.
What should have happened is automatic replacement of such path strings
with a CMake-side configuration variable (e.g. ${toolkit_INCLUDE_DIR})
via a regular expression in the mappings file (include_mappings.txt).
Then CMake will consult the setting at ${toolkit_INCLUDE_DIR}
(which should have been gathered during a CMake configure run, probably
within one of the vcproj2cmake hook scripts that are explained above).

If things appear to be failing left and right,
the reason might be a lack of CMake proficiency, thus it's perhaps best
to start with a new small CMake sample project
(perhaps use one of the samples on the internet) before using this converter,
to gain some CMake experience (CMake itself has a rather steep learning curve,
thus it might be even worse trying to start with an Alpha-stage
.vcproj to CMake converter).


=== Installation/packaging ===

Installation/packaging of a vcproj2cmake-based project is not specially supported yet,
however I'm currently in the process of setting packaging up locally,
thus hopefully this will eventually result in a nicely generic, easily usable
(and optionally overridable!) mechanism which provides a nice Bundle-like
packaging functionality on all platforms (Mac _and_ Linux, and Windows etc.).

I just finished packaging, but in my case all I had to do was to use
GetPrerequisites.cmake on the main project target (i.e., the main executable),
this listed all sub project targets already and allowed me to install them
from a global configuration part.
Thus there's no special per-project vcproj2cmake handling yet.


=== Related projects, alternative setups ===

sln2mak (.sln to Makefile converter), http://www.codeproject.com/KB/cross-platform/sln2mak.aspx

I just have to state that we have a very unfair advantage here:
while this script implementation possibly might be better
than our converter (who knows...), the fact that we are converting
towards CMake (and thus to a whole universe of supported build environments
/IDEs via CMake's generators) probably renders any shortcomings
that we might have rather very moot.


A completely alternative way of gaining cross-platform builds
other than making use of CMake via vcproj2cmake
may be to stay within proprietary .vcproj / Visual Studio realms
and to implement a cross-compiler setup
- this is said to be doable, and perhaps it can even be preferrable (would be nice
  to receive input in case anyone has particular experience in this area).


=== Off-Topic parts ===

If someone is still making use of the SCM (Source Control Management)
abomination called VSS
and contemplating migrating to a different, actually usable system,
then it may be useful to NOT default-decide to go for the "obvious" successor
(Microsoft TFS), but instead making an Informed Decision (tm) of which
capable SCM (or in fact, an integrated Tracker/Ticket environment [ALM]) to choose.
While TFS is an awful lot better than VSS, it still has some painful
shortcomings, among these:
- no three-way-merges via common base version, i.e. base-less merge
  http://jamesmckay.net/2011/01/baseless-merges-in-team-foundation-server-why/
- no disconnected SCM operation (server connection required)
- installation is a veritable PITA

For a very revealing discussion with lots of experienced SCM/ALM people,
you may look at
http://jamesmckay.net/2011/02/team-foundation-server-is-the-lotus-notes-of-version-control-tools/

In short, it is strongly advisable to also check out other (possibly much more
transparently developed) ALMs such as Trac before committing to a specific product
(these environments make up a large part of your development inner loop,
thus a wrong choice will cost dearly in wasted time and inefficiency).
http://almatters.wordpress.com/2010/08/19/alm-open-source-tools-eclipse-mylyn-subclipse-trac-subversion/


While git might be an obvious cross-platform SCM candidate, Windows integration of Mercurial
probably is somewhat better.
Useful URLs:
http://mercurial.selenic.com/wiki/SourceSafeConversion
http://code.google.com/p/vss2git/
http://code.google.com/p/gitextensions/



=== Epilogue ===

Whenever something needs better explanation, just tell me and I'll try to improve it.
Dito if you think that some mechanism is poorly implemented (we're still at pre-Beta stage!).

Despite being at Alpha stage, the converter is now more than usable enough
to successfully build a very large project consisting of several dozen sub projects.

Happy hacking,

Andreas Mohr <andi@lisas.de>
