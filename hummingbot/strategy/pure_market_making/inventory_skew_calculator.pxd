cdef object c_calculate_bid_ask_ratios_from_base_asset_ratio(double base_asset_amount,
                                                             double quote_asset_amount,
                                                             double price,
                                                             double target_base_asset_ratio,
                                                             double base_asset_range)

cdef object c_calculate_bid_ask_spread_ratios_from_base_asset_ratio_v1(
                                                            double base_asset_amount,
                                                            double quote_asset_amount,
                                                            double price,
                                                            double skew_threshold,
                                                            double maximum_skew_factor)

cdef object c_calculate_bid_ask_spread_ratios_from_base_asset_ratio_v2(
                                                            double base_asset_amount,
                                                            double quote_asset_amount,
                                                            double price,
                                                            double target_base_asset_ratio,
                                                            double base_asset_range,
                                                            double maximum_skew_factor)