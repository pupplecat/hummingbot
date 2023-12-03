from decimal import Decimal
import numpy as np

from .data_types import InventorySkewBidAskRatios

decimal_0 = Decimal(0)
decimal_1 = Decimal(1)
decimal_2 = Decimal(2)


def calculate_total_order_size(order_start_size: Decimal, order_step_size: Decimal = decimal_0,
                               order_levels: int = 1) -> Decimal:
    order_levels_decimal = order_levels
    return (decimal_2 *
            (order_levels_decimal * order_start_size +
             order_levels_decimal * (order_levels_decimal - decimal_1) / decimal_2 * order_step_size
             )
            )


def calculate_bid_ask_ratios_from_base_asset_ratio(
        base_asset_amount: float, quote_asset_amount: float, price: float,
        target_base_asset_ratio: float, base_asset_range: float) -> InventorySkewBidAskRatios:
    return c_calculate_bid_ask_ratios_from_base_asset_ratio(base_asset_amount,
                                                            quote_asset_amount,
                                                            price,
                                                            target_base_asset_ratio,
                                                            base_asset_range)

def calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
        base_asset_amount: float, quote_asset_amount: float, price: float,
        skew_threshold: float, maximum_skew_factor: float) -> InventorySkewBidAskRatios:
    return c_calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(base_asset_amount,
                                                            quote_asset_amount,
                                                            price,
                                                            skew_threshold,
                                                            maximum_skew_factor)

def calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
        base_asset_amount: float, quote_asset_amount: float, price: float,
        target_base_asset_ratio: float, base_asset_range: float, maximum_skew_factor: float) -> InventorySkewBidAskRatios:
    return c_calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(base_asset_amount,
                                                            quote_asset_amount,
                                                            price,
                                                            target_base_asset_ratio,
                                                            base_asset_range,
                                                            maximum_skew_factor)

cdef object c_calculate_bid_ask_ratios_from_base_asset_ratio(
        double base_asset_amount, double quote_asset_amount, double price,
        double target_base_asset_ratio, double base_asset_range):
    cdef:
        double total_portfolio_value = base_asset_amount * price + quote_asset_amount

    if total_portfolio_value <= 0.0 or base_asset_range <= 0.0:
        return InventorySkewBidAskRatios(0.0, 0.0)

    cdef:
        double base_asset_value = base_asset_amount * price
        double base_asset_range_value = min(base_asset_range * price, total_portfolio_value * 0.5)
        double target_base_asset_value = total_portfolio_value * target_base_asset_ratio
        double left_base_asset_value_limit = max(target_base_asset_value - base_asset_range_value, 0.0)
        double right_base_asset_value_limit = target_base_asset_value + base_asset_range_value
        double left_inventory_ratio = np.interp(base_asset_value,
                                                [left_base_asset_value_limit, target_base_asset_value],
                                                [0.0, 0.5])
        double right_inventory_ratio = np.interp(base_asset_value,
                                                 [target_base_asset_value, right_base_asset_value_limit],
                                                 [0.5, 1.0])
        double bid_adjustment = (np.interp(left_inventory_ratio, [0, 0.5], [2.0, 1.0])
                                 if base_asset_value < target_base_asset_value
                                 else np.interp(right_inventory_ratio, [0.5, 1], [1.0, 0.0]))
        double ask_adjustment = 2.0 - bid_adjustment

    return InventorySkewBidAskRatios(bid_adjustment, ask_adjustment)

cdef object c_calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
        double base_asset_amount, double quote_asset_amount, double price,
        double skew_threshold, double maximum_skew_factor):

    if base_asset_amount <= 0.0 or quote_asset_amount <= 0.0 or skew_threshold <= 0.0 or maximum_skew_factor <= 0.0:
        return InventorySkewBidAskRatios(1.0, 1.0)

    cdef double base_asset_value = base_asset_amount * price
    cdef double skew_ratio = base_asset_value / (base_asset_value + quote_asset_amount)

    if skew_ratio <= skew_threshold:
        return InventorySkewBidAskRatios(1.0, 1.0)

    cdef double skew_factor = 1 + (skew_ratio - skew_threshold) * maximum_skew_factor

    return InventorySkewBidAskRatios(skew_factor, skew_factor)


cdef object c_calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
        double base_asset_amount, double quote_asset_amount, double price,
        double target_base_asset_ratio, double base_asset_range, double maximum_skew_factor):
    cdef:
        double total_portfolio_value = base_asset_amount * price + quote_asset_amount

    if total_portfolio_value <= 0.0 or base_asset_range <= 0.0 or maximum_skew_factor <= 0.0:
        return InventorySkewBidAskRatios(1.0, 1.0)

    cdef:
        double base_asset_value = base_asset_amount * price
        double base_asset_range_value = min(base_asset_range * price, total_portfolio_value * 0.5)
        double target_base_asset_value = total_portfolio_value * target_base_asset_ratio
        double left_base_asset_value_limit = max(target_base_asset_value - base_asset_range_value, 0.0)
        double right_base_asset_value_limit = target_base_asset_value + base_asset_range_value
        double half_point = maximum_skew_factor * 0.5
        double left_inventory_ratio = np.interp(base_asset_value,
                                        [left_base_asset_value_limit, target_base_asset_value],
                                        [0, half_point])
        double right_inventory_ratio = np.interp(base_asset_value,
                                                    [target_base_asset_value, right_base_asset_value_limit],
                                                    [half_point, maximum_skew_factor])
        double bid_adjustment = left_inventory_ratio if base_asset_value < target_base_asset_value else right_inventory_ratio
        double ask_adjustment = maximum_skew_factor - bid_adjustment

    return InventorySkewBidAskRatios(1.0 + bid_adjustment, 1.0 + ask_adjustment)

# double left_inventory_ratio = np.interp(base_asset_value,
#                                         [left_base_asset_value_limit, target_base_asset_value],
#                                         [2, 1])
# double right_inventory_ratio = np.interp(base_asset_value,
#                                             [target_base_asset_value, right_base_asset_value_limit],
#                                             [1, 0])
# double bid_adjustment = left_inventory_ratio if base_asset_value < target_base_asset_value else right_inventory_ratio
# double ask_adjustment = 2.0 - bid_adjustment

# ---------------------

# # Varying the value of base_asset_value
# base_asset_values = [50, 200, 500, 800, 1000]

# # Function to calculate bid and ask adjustments using the first expression
# def calculate_first_expression(base_asset_value):
#     left_inventory_ratio = np.interp(base_asset_value,
#                                      [left_base_asset_value_limit, target_base_asset_value],
#                                      [0.0, 0.5])
#     right_inventory_ratio = np.interp(base_asset_value,
#                                       [target_base_asset_value, right_base_asset_value_limit],
#                                       [0.5, 1.0])
#     bid_adjustment = (np.interp(left_inventory_ratio, [0, 0.5], [2.0, 1.0])
#                       if base_asset_value < target_base_asset_value
#                       else np.interp(right_inventory_ratio, [0.5, 1], [1.0, 0.0]))
#     ask_adjustment = 2.0 - bid_adjustment
#     return bid_adjustment, ask_adjustment

# # Function to calculate bid and ask adjustments using the second expression
# def calculate_second_expression(base_asset_value):
#     left_inventory_ratio = np.interp(base_asset_value,
#                                      [left_base_asset_value_limit, target_base_asset_value],
#                                      [2, 1])
#     right_inventory_ratio = np.interp(base_asset_value,
#                                       [target_base_asset_value, right_base_asset_value_limit],
#                                       [1, 0])
#     bid_adjustment = left_inventory_ratio if base_asset_value < target_base_asset_value else right_inventory_ratio
#     ask_adjustment = 2.0 - bid_adjustment
#     return bid_adjustment, ask_adjustment

# # Compare the values for each base_asset_value
# results_first_expression = [calculate_first_expression(val) for val in base_asset_values]
# results_second_expression = [calculate_second_expression(val) for val in base_asset_values]

# results_first_expression, results_second_expression

# ([(2.0, 0.0), (1.75, 0.25), (1.0, 1.0), (0.25, 1.75), (0.0, 2.0)],
#  [(2.0, 0.0), (1.75, 0.25), (1.0, 1.0), (0.25, 1.75), (0.0, 2.0)])