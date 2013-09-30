//
//  ZZActivity.h
//  Activity
//
//  Created by Denis Bohm on 11/8/11.
//

#ifndef Activity_ZZActivity_h
#define Activity_ZZActivity_h

typedef double ZZActivityValue;
typedef double ZZActivityTime;

@protocol ZZActivityDelegate <NSObject>

- (void)activityValue:(ZZActivityValue)value time:(ZZActivityTime)time;

@end

#endif
