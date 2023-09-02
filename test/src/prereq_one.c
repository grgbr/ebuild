/******************************************************************************
 * SPDX-License-Identifier: GPL-3.0-only
 *
 * This file is part of eBuild.
 * Copyright (C) 2019-2023 Grégor Boirie <gregor.boirie@free.fr>
 ******************************************************************************/

#include <stdio.h>

int
prereq_one(void)
{
	printf("this is prereq one\n");
	return 0;
}
