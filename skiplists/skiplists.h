//
//  skiplists.h
//  skiplists
//
//  Created by Peter da Silva on 6/11/16.
//  Copyright © 2016 Flightaware. All rights reserved.
//

#ifndef skiplists_h
#define skiplists_h

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct CSkipListNode {
    char *keyString;
    int level;
    void *value;
    struct CSkipListNode **next;
};

struct CSkipList {
    struct CSkipListNode *head;
    int maxLevels;
    int level;
    int type; // reserved
};

#define SKIPLIST_UNKNOWN 0
#define SKIPLIST_STRING 1
#define SKIPLIST_INT 2
#define SKIPLIST_DOUBLE 3

struct CSkipListSearch {
    struct CSkipList *parent;
    struct CSkipListNode **update;
    struct CSkipListNode *node;
    int state;
};

#define SEARCH_STATE_NONE 0         // Not a valid search, either new or an insert/delete operation has occurred
#define SEARCH_STATE_FOUND 1        // Search is complete, and a key (may not be exact match) was found
#define SEARCH_STATE_TRAVERSE 2     // Search is complete, and no key was found
#define SEARCH_STATE_NOT_FOUND 3    // Search is currently traversing the list

struct CSkipList *newCSkipList(int maxLevels, int type);
void destroySkipList(struct CSkipList *list);
int searchSkipList(struct CSkipList *list, char *key);
int searchMatchedExactString(struct CSkipListSearch *search, char *keyString);
int insertBeforePossibleMatchString(struct CSkipListSearch *search, char *keyString, void *value);
int deleteMatchedNode(struct CSkipListSearch *search);
char *getMatchedKeyString(struct CSkipListSearch *search);
void *getMatchedValue(struct CSkipListSearch *search);
int setMatchedValue(struct CSkipListSearch *search, void *value);
int advanceSearchNode(struct CSkipListSearch *search);


#endif /* skiplists_h */
