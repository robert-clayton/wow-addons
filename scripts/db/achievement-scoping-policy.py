"""Achievement scoping policy for the shipped catalog (1.16).

Collectionist ships an achievement only if it meets at least one of four tests:

  1. It is a direct collection-oriented task (category "collections").
  2. It is a sub-requirement of a meta that rewards a collectible or a title,
     resolved through the CriteriaTree Type-8 achievement-reference graph.
  3. It directly rewards a collectible or a title.
  4. Its group source is an expansion-defining feature -- see FEATURE_SOURCES.

Applying that to the pre-1.16 catalog kept 2,310 of 4,347 achievements and
dropped 2,037. The surviving ids are what the data files hold; the dropped ids
are listed in research/collectionist/sources/dropped-achievements.json, and
scripts/db/prune-achievements.py is the tool that removed them.

This file is the POLICY RECORD, not a runnable classifier. Criteria 1-3 were
resolved against DB2 (Achievement, CriteriaTree) plus the addon's own catalog,
in an analysis that is reproducible from those tables but was not driven by a
single committed script. Criterion 4 is fully captured here, because it is a
judgement call about which sources count as features and that judgement is the
part worth keeping under review.

Criterion 3 has one refinement worth recording: the DB2 reward column alone
misses achievements whose reward is recorded in Collectionist's own catalog.
Four rows (10398, 11340, 61083, 63679) were the stated source of a mount, toy
or pet while carrying no DB2 reward, and an early pass dropped them. Every
achievementID referenced by a Mounts/Pets/Toys/Decorations row is therefore
treated as a criterion-3 keep, whatever DB2 says.
"""

# Expansion-defining systems: the thing an expansion is built around and that
# goes away when it ends. Deliberately NOT raids, dungeons, reputations or
# battlegrounds -- those are perennial content types, not features, and lumping
# them in would keep 1,500 rows the policy is meant to remove.
FEATURE_SOURCES = {
    "dragonriding", "delves", "covenants", "scenarios", "islands", "torghast",
    "buildings", "season", "war_effort", "showdowns", "shipyard", "missions",
    "artifacts", "prey", "invasions", "garrison", "void_assaults",
    "ritual_sites", "followers", "heart_of_azeroth", "class_hall", "monuments",
    "housing", "abundance", "timeless", "proving", "events",
}
# Perennial content, explicitly excluded even though the data files file them
# under the "features" category:
#   raid, dungeons, reputation, tournament, professions, and every battleground
#   (ashran, twinpeaks, wintergrasp, warsong, alterac, arathi, gilneas,
#    tolbarad, eye_of_storm, silvershard, kotmogu, deepwind)
