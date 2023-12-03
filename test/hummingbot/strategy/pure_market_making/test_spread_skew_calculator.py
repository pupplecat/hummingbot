#!/usr/bin/env python
import unittest

from hummingbot.strategy.pure_market_making.data_types import InventorySkewBidAskRatios
from hummingbot.strategy.pure_market_making.inventory_skew_calculator import (
    calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1,
    calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2,
)


class SpreadSkewCalculatorUnitTest(unittest.TestCase):
    def setUp(self):
        self.base_asset: float = 85000
        self.quote_asset: float = 10000
        self.price: float = 0.0036
        self.target_ratio: float = 0.03
        self.base_range: float = 20000.0

    def test_v1_zero_value(self):
        self.base_asset = 100
        self.quote_asset = 10
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 200
        self.skew_threshold = 0.05
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
            0, self.quote_asset, self.price, self.skew_threshold, self.maximum_skew_factor
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
            self.base_asset, 0, self.price, self.skew_threshold, self.maximum_skew_factor
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
            self.base_asset, self.quote_asset, self.price, 0, self.maximum_skew_factor
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
            self.base_asset, self.quote_asset, self.price, self.skew_threshold, 0
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

    def test_v1_skew_ration_less_than_threshold(self):
        self.base_asset = 1
        self.quote_asset = 100
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 200
        self.skew_threshold = 0.05
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
            self.base_asset, self.quote_asset, self.price, self.skew_threshold, self.maximum_skew_factor
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

    def test_v1_return_skew_factor(self):
        self.base_asset = 50
        self.quote_asset = 100
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 200
        self.skew_threshold = 0.05
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
            self.base_asset, self.quote_asset, self.price, self.skew_threshold, self.maximum_skew_factor
        )
        self.assertAlmostEqual(2.416666, bid_ask_ratios.bid_ratio, places=5)
        self.assertAlmostEqual(2.416666, bid_ask_ratios.ask_ratio, places=5)

    def test_v2_zero_value(self):
        self.base_asset = 100
        self.quote_asset = 10
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 200
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
            0, 0, self.price, self.target_ratio, self.base_range, self.maximum_skew_factor
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
            self.base_asset, self.quote_asset, self.price, self.target_ratio, 0, self.maximum_skew_factor
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
            self.base_asset, self.quote_asset, self.price, self.target_ratio, self.base_range, 0
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

    def test_v2_asset_less_than_left_band(self):
        self.base_asset = 1
        self.quote_asset = 100
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 2
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
            self.base_asset, self.quote_asset, self.price, self.target_ratio, self.base_range, self.maximum_skew_factor
        )
        self.assertAlmostEqual(1.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(6.0, bid_ask_ratios.ask_ratio)

    def test_v2_asset_greater_than_right_band(self):
        self.base_asset = 80
        self.quote_asset = 100
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 2
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
            self.base_asset, self.quote_asset, self.price, self.target_ratio, self.base_range, self.maximum_skew_factor
        )
        self.assertAlmostEqual(6.0, bid_ask_ratios.bid_ratio)
        self.assertAlmostEqual(1.0, bid_ask_ratios.ask_ratio)

    def test_v2_asset_within_left_band(self):
        self.base_asset = 30
        self.quote_asset = 100
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 30
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
            self.base_asset, self.quote_asset, self.price, self.target_ratio, self.base_range, self.maximum_skew_factor
        )
        self.assertAlmostEqual(2.2083333, bid_ask_ratios.bid_ratio, places=5)
        self.assertAlmostEqual(4.7916666, bid_ask_ratios.ask_ratio, places=5)

    def test_v2_asset_within_right_band(self):
        self.base_asset = 60
        self.quote_asset = 100
        self.price = 1
        self.target_ratio = 0.35
        self.base_range = 30
        self.maximum_skew_factor = 5
        bid_ask_ratios: InventorySkewBidAskRatios = calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
            self.base_asset, self.quote_asset, self.price, self.target_ratio, self.base_range, self.maximum_skew_factor
        )
        self.assertAlmostEqual(3.8333333, bid_ask_ratios.bid_ratio, places=5)
        self.assertAlmostEqual(3.1666666, bid_ask_ratios.ask_ratio, places=5)


if __name__ == "__main__":
    unittest.main()
