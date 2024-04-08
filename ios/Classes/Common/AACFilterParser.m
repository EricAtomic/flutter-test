//
//  FilterApplier.m
//  atomic_sdk_flutter
//
//  Created by William Bryant on 15/01/24.
//
#import "AACFilterParser.h"
#import "NSString+ParsedDate.h"

@import AtomicSDK;

@implementation AACFilterParser

+ (NSArray<AACCardFilter *> *)parseFiltersFromJson:(NSArray<NSDictionary<NSString *, id> *> *)filterJsons {
    NSMutableArray<AACCardFilter *> *filters = [NSMutableArray array];

    for (NSDictionary<NSString *, id> *filterJson in filterJsons) {
        for (NSString *filterName in filterJson) {
            id rawValue = filterJson[filterName];
            AACCardFilter *filter = nil;
            if ([filterName isEqualToString:@"byCardInstanceId"]) {
                filter = [AACCardListFilter filterByCardInstanceId:(NSString*)rawValue];
            } else {
                filter = [self tryParseFilterFromJson:filterName filterValueJson:rawValue];
            }
            if (filter) {
                [filters addObject:filter];
            }
        }
    }
    return filters;
}

+ (AACCardFilter *)tryParseFilterFromJson:(NSString *)filterName filterValueJson:(id)filterValueJson {
    NSMutableArray<AACCardFilterValue *> *filterValues = [NSMutableArray array];
    if ([filterValueJson isKindOfClass:[NSDictionary class]]) {
        // If it's a filter that uses 1 value, e.g: equalTo={byPriority=3}
        NSDictionary<NSString *, id> *filterValueDict = (NSDictionary<NSString *, id> *)filterValueJson;
        for (NSString *rawOperator in filterValueDict) {
            AACCardFilterValue *filterValue = [self tryParseFilterValue:rawOperator rawValue:filterValueDict[rawOperator]];
            if (filterValue) {
                [filterValues addObject:filterValue];
            }
        }
    } else if ([filterValueJson isKindOfClass:[NSArray class]]) {
        
        // If it's a filter that uses multiple values, (e.g. contains=[{ByPriority=1}, {ByPriority=5]}).
        NSArray<NSDictionary<NSString *, id> *> *filterValueArray = (NSArray<NSDictionary<NSString *, id> *> *)filterValueJson;
        for (NSDictionary<NSString *, id> *rawFilter in filterValueArray) {
            for (NSString *rawOperator in rawFilter) {
                AACCardFilterValue *filterValue = [self tryParseFilterValue:rawOperator rawValue:rawFilter[rawOperator]];
                if (filterValue) {
                    [filterValues addObject:filterValue];
                }
            }
        }
    }

    if (filterValues.count == 0) {
        return nil;
    }

    return [self tryParseFilterFromName:filterName filterValues:filterValues];
}

+ (AACCardFilter *)tryParseFilterFromName:(NSString *)filterName filterValues:(NSArray<AACCardFilterValue *> *)filterValues {
    if ([filterName isEqualToString:@"equalTo"]) {
        return [AACCardListFilter filterByCardsEqualTo:[filterValues firstObject]];
    } else if ([filterName isEqualToString:@"notEqualTo"]) {
        return [AACCardListFilter filterByCardsNotEqualTo:[filterValues firstObject]];
    } else if ([filterName isEqualToString:@"greaterThan"]) {
        return [AACCardListFilter filterByCardsGreaterThan:[filterValues firstObject]];
    } else if ([filterName isEqualToString:@"greaterThanOrEqualTo"]) {
        return [AACCardListFilter filterByCardsGreaterThanOrEqualTo:[filterValues firstObject]];
    } else if ([filterName isEqualToString:@"lessThan"]) {
        return [AACCardListFilter filterByCardsLessThan:[filterValues firstObject]];
    } else if ([filterName isEqualToString:@"lessThanOrEqualTo"]) {
        return [AACCardListFilter filterByCardsLessThanOrEqualTo:[filterValues firstObject]];
    } else if ([filterName isEqualToString:@"contains"]) {
        return [AACCardListFilter filterByCardsIn:filterValues];
    } else if ([filterName isEqualToString:@"notIn"]) {
        return [AACCardListFilter filterByCardsNotIn:filterValues];
    } else if ([filterName isEqualToString:@"between"]) {
        return [AACCardListFilter filterByCardsBetweenStartValue:filterValues[0] endValue:filterValues[1]];
    }
    return nil;
}

+ (AACCardFilterValue *)tryParseFilterValue:(NSString *)rawOperator rawValue:(id)rawValue {
    if ([rawOperator isEqualToString:@"byPriority"]) {
        return [AACCardFilterValue byPriority:[rawValue intValue]];
    } else if ([rawOperator isEqualToString:@"byCreatedDate"]) {
        NSDate *date = [(NSString *)rawValue aacFlutter_NSDateFromDateString];
        return date ? [AACCardFilterValue byCreatedDate:date] : nil;
    } else if ([rawOperator isEqualToString:@"byCardTemplateId"]) {
        return [AACCardFilterValue byCardTemplateID:rawValue];
    } else if ([rawOperator isEqualToString:@"byCardTemplateName"]) {
        return [AACCardFilterValue byCardTemplateName:rawValue];
    } else if ([rawOperator isEqualToString:@"byVariableName"]) {
        NSDictionary<NSString *, id> *cVars = (NSDictionary<NSString *, id> *)rawValue; // cVar means custom variable
        for (NSString *cVarName in cVars) {
            id cVarValue = cVars[cVarName];
            if (cVarValue) {
                if ([cVarValue isKindOfClass:[NSString class]]) {
                    NSDate *cVarDate = [(NSString *)cVarValue aacFlutter_NSDateFromDateString];
                    return cVarDate ? [AACCardFilterValue byVariableName:cVarName date:cVarDate] : [AACCardFilterValue byVariableName:cVarName string:cVarValue];
                } else if ([cVarValue isKindOfClass:[NSNumber class]]){
                    if ([cVarValue respondsToSelector:@selector(boolValue)]) {
                        BOOL cVarBool = [(NSNumber *)cVarValue boolValue];
                        return [AACCardFilterValue byVariableName:cVarName boolean:cVarBool];
                    }
                    return [AACCardFilterValue byVariableName:cVarName number:cVarValue];
                }
            }
        }
    }
    return nil;
}

@end
