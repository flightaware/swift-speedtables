//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

struct SkipList *newSkipList(int maxLevels, int type);
void destroySkipList(struct SkipList *list);
int searchSkipList(struct SkipList *list, char *key);
int searchMatchedExact(struct SkipList *list, char *key);
void *matchedValue(struct SkipList *list);
int insertBeforePossibleMatch(struct SkipList *list, char *key, void *value);
int deleteMatchedNode(struct SkipList *list);