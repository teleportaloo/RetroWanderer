//
//  TileNeighbors.h
//  Text Wanderer
//
//  Created by Andrew Wallace on 8/2/20.
//  Copyright © 2020 Teleportaloo. All rights reserved.
//

/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#ifndef TileNeighbors_h
#define TileNeighbors_h

typedef struct _tile_neighbors {
    char tile;
    char left;
    char right;
    char up;
    char down;
} TileNeighbors;


static inline TileNeighbors TileNeighborsMake(char tile, char left, char right, char up, char down) {
    TileNeighbors n;

    n.tile = tile;
    n.left = left;
    n.right = right;
    n.up = up;
    n.down = down;
    return n;
}

#define NoTileNeighbors(X) TileNeighborsMake((X), 0, 0, 0, 0)


#endif /* TileNeighbors_h */
