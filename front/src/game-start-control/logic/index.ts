import {
    OptionSuggestion,
} from '../../defs/casting-definition';
import {
    RoleCategoryDefinition,
} from '../../defs/category-definition';
import {
    RuleGroup,
    RuleDefinition,
} from '../../defs/rule-definition';

import {
    showConfirmDialog,
} from '../../dialog';
import {
    i18n,
} from '../../i18n';
import {
    findLabeledGroupItem,
} from '../../util/labeled-group';
import {
    CastingStore,
} from '../store';

import {
    getQuery,
} from './query';
import {
    checkSuggestion,
    getRuleExpression,
} from '../../logic/rule';

export interface GameStartInput {
    i18n: i18n,
    roles: string[];
    categories: RoleCategoryDefinition[];
    ruledefs: RuleGroup,
    store: CastingStore;
}
/**
 * Logic of game start.
 * @returns {Promise} Promise which resolves to query object if game can be started, undefined otherwise.
 */
export async function gameStart({
    i18n,
    roles,
    categories,
    ruledefs,
    store,
}: GameStartInput): Promise<Record<string, string> | undefined> {
    const {
        currentCasting,
        rules,
    } = store;
    const query = getQuery(roles, categories, store);

    // Check suggested options.
    if (currentCasting.suggestedOptions != null) {
        for (const id in currentCasting.suggestedOptions) {
            // retrieve rule setting.
            const rule = findLabeledGroupItem(ruledefs, (rule)=> rule.id === id);
            if (rule == null) {
                continue;
            }
            const sug = currentCasting.suggestedOptions[id];
            // Current value of this rule.
            const val = rules.get(id);
            if (val == null) {
                throw new Error(`undefined value of rule '${id}'`);
            }

            if (!checkSuggestion(val, sug)) {
                // This is not suggested setting.
                const res = await showConfirmDialog({
                    modal: true,
                    message: suggestionMessage(i18n, rule, sug),
                    yes: i18n.t('game_client:gamestart.confirm.ruleSuggestion.yes'),
                    no: i18n.t('game_client:gamestart.confirm.ruleSuggestion.no'),
                });
                if (res) {
                    // User selected to stop.
                    return undefined;
                }
            }
        }
    }

    return undefined;
}

/**
 * Make a suggestion message.
 */
function suggestionMessage(
    i18n: i18n,
    rule: RuleDefinition,
    suggestion: OptionSuggestion,
): string {
    const t = i18n.t.bind(i18n);

    let lbl;
    let sug;
    if ('string' === typeof suggestion) {
        // get a rulestring for this suggestion.
        const {
            label,
            value,
        } = getRuleExpression(t, rule, suggestion);

        lbl = label;
        sug = i18n.t('game_client:gamestart.confirm.ruleSuggestion.valueSuggestion', {
            value,
        });
    } else switch (suggestion.type) {
        case 'range': {
            const {
                min,
                max,
            } = suggestion;
            if (min != null && max != null) {
                const minobj = getRuleExpression(t, rule, String(min));
                const maxobj = getRuleExpression(t, rule, String(max));

                lbl = minobj.label;
                sug = i18n.t('game_client:gamestart.confirm.ruleSuggestion.rangeSuggestionMinMax', {
                    min: minobj.value,
                    max: maxobj.value,
                });
            } else if (min != null) {
                const minobj = getRuleExpression(t, rule, String(min));

                lbl = minobj.label;
                sug = i18n.t('game_client:gamestart.confirm.ruleSuggestion.rangeSuggestionMin', {min: minobj.value});
            } else if (max != null) {
                const maxobj = getRuleExpression(t, rule, String(max));

                lbl = maxobj.label;
                sug = i18n.t('game_client:gamestart.confirm.ruleSuggestion.rangeSuggestionMax', {max: maxobj.value});
            } else {
                console.warn('Range suggestion does not make sense');
                lbl = '';
                sug = '';
            }
            break;
        }
    }
    return i18n.t('game_client:gamestart.confirm.ruleSuggestion.message', {
        name: lbl,
        suggestion: sug,
    });
}
