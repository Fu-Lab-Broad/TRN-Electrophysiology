import numpy as np
import pandas as pd
from ABFbot_functions import *

def detect_bursts(peak_indices, time_resolution, frequency_threshold = 10):
    burst_list = []
    num_previous_less_threshold_tonic = 0
    num_previous_less_100ms = 0
    for index in range(len(peak_indices)):
        is_starting_burst = False
        is_ending_burst = False
        is_in_burst = False
        is_starting_event = False

        is_less_100ms = False
        is_less_500ms = False
        
        is_starting_tonic = False
        is_ending_tonic = False
        is_in_tonic = False
        
        if index == 0:
            ptp_interval_pre = 40000
            ptp_interval_post = peak_indices[index+1] - peak_indices[index]
        if index == (len(peak_indices)-1):
            ptp_interval_pre = peak_indices[index] - peak_indices[index-1]
            ptp_interval_post = 40000
        if (index > 0) & (index < (len(peak_indices)-1)):
            ptp_interval_pre = peak_indices[index] - peak_indices[index-1]
            ptp_interval_post = peak_indices[index+1] - peak_indices[index]
        
        # burst threshold > 10 Hz, which is equivalent to ptp_interval < 0.1 s (1000 indices)
        ptp_threshold = (1/frequency_threshold) * 10000
        if ptp_interval_pre < ptp_threshold:
            is_starting_burst = False
            is_in_burst = True

        if ptp_interval_post < ptp_threshold:
            is_ending_burst = False
            is_in_burst = True
        
        if (ptp_interval_pre >= ptp_threshold) & (ptp_interval_post < ptp_threshold):
            is_starting_burst = True
            is_starting_event = True
        
        if (ptp_interval_pre < ptp_threshold) & (ptp_interval_post >= ptp_threshold):
            is_ending_burst = True
        
        if (ptp_interval_pre >= ptp_threshold) & (ptp_interval_post >= ptp_threshold):
            is_in_burst = False
            is_starting_event = True
        
        # tonic firing threshold > 2Hz, >= 10 peaks; or 2-10Hz, >= 7 peaks;
        threshold_tonic = 5000
        is_less_threshold_tonic = False
        is_less_100ms = False
        if ptp_interval_pre < threshold_tonic:
            is_less_threshold_tonic = True
            num_previous_less_threshold_tonic += 1
            if ptp_interval_pre < ptp_threshold:
                is_less_100ms = True
                num_previous_less_100ms += 1
            else:
                num_previous_less_100ms = 0
        else:
            num_previous_less_threshold_tonic = 0
            num_previous_less_100ms = 0

        burst_list.append(
            [
                peak_indices[index],
                is_starting_burst,
                is_ending_burst,
                is_in_burst,
                is_starting_event,
                ptp_interval_pre,
                is_less_threshold_tonic,
                is_less_100ms,
                num_previous_less_threshold_tonic,
                num_previous_less_100ms,
                is_starting_tonic,
                is_ending_tonic,
                is_in_tonic
            ]
        )
    
    df_peak_info = pd.DataFrame(
        burst_list,
        columns=[
            'peak_index',
            'is_starting_burst',
            'is_ending_burst',
            'is_in_burst',
            'is_starting_event',
            'ptp_interval_pre',
            'is_less_threshold_tonic',
            'is_less_100ms',
            'num_previous_less_threshold_tonic',
            'num_previous_less_100ms',
            'is_starting_tonic',
            'is_ending_tonic',
            'is_in_tonic'
        ]
    )

    # detect tonic firing
    for index in range(len(peak_indices)-9):
        neighbors_next10 = list(range(index, index+10))
        condition1 = np.all(df_peak_info['is_less_threshold_tonic'][neighbors_next10])
        ptp_max = df_peak_info['ptp_interval_pre'][neighbors_next10].max()
        ptp_min = df_peak_info['ptp_interval_pre'][neighbors_next10].min()
        condition2 = (ptp_max/ptp_min) < 3
        if condition1 & condition2:
            df_peak_info.loc[list(range(index-1, index+10)), 'is_in_tonic'] = True

            if df_peak_info['num_previous_less_threshold_tonic'][index] == 0:
                is_starting_tonic == True
            

    # check bursts round 2
    num_bursts = df_peak_info['is_starting_burst'].sum()
    index_starting_burst = None
    index_ending_burst = None
    burst_position = 0
    burst_end_index_list = df_peak_info.index[
        df_peak_info['is_ending_burst'] == True
    ].tolist()

    for index in range(len(df_peak_info)):
        if df_peak_info['is_starting_burst'][index]:
            index_starting_burst = index
            index_ending_burst = burst_end_index_list[burst_position]
            burst_position += 1

            ### remove burst if ibi > 5 sec
            if df_peak_info.at[index_starting_burst, 'ptp_interval_pre'] > 50000:
                df_peak_info.loc[index_starting_burst:, 'is_starting_burst'] = False
                df_peak_info.loc[index_starting_burst:, 'is_ending_burst'] = False
                df_peak_info.loc[index_starting_burst:, 'is_in_burst'] = False
                df_peak_info.loc[index_starting_burst:, 'is_starting_event'] = True

            ### Remove short ones
            condition1 = index_ending_burst - index_starting_burst <= 1
            condition2 = df_peak_info.at[index_starting_burst, 'is_in_tonic'] == True
            if condition1 & condition2:
                df_peak_info.loc[index_starting_burst:index_ending_burst+1, 'is_starting_burst'] = False
                df_peak_info.loc[index_starting_burst:index_ending_burst+1, 'is_ending_burst'] = False
                df_peak_info.loc[index_starting_burst:index_ending_burst+1, 'is_in_burst'] = False
                df_peak_info.loc[index_starting_burst:index_ending_burst+1, 'is_starting_event'] = True

            ### Cut long ones
            for index2 in range(index_starting_burst, index_ending_burst+1):
                if index2 >= len(peak_indices)-3:
                    break
                post_distance = peak_indices[index2+1] - peak_indices[index2]
                post_post_distance = peak_indices[index2+2] - peak_indices[index2+1]
                pre_distance = peak_indices[index2] - peak_indices[index2-1]

                condition1 = (peak_indices[index2] - peak_indices[index_starting_burst]) > 200
                condition2 = post_distance > pre_distance
                condition3 = post_distance > post_post_distance
                # condition4 = df_peak_info.at[index2, 'is_ending_burst'] == False
                condition5 = df_peak_info.at[index2, 'is_in_tonic'] == True
                if condition1 & condition2 & condition3 & condition5:
                    df_peak_info.loc[index2:, 'is_starting_burst'] = False
                    df_peak_info.at[index2, 'is_ending_burst'] = True
                    df_peak_info.loc[index2+1:, 'is_ending_burst'] = False
                    df_peak_info.at[index2:, 'is_in_burst'] = True
                    df_peak_info.loc[index2+1:, 'is_in_burst'] = False
                    df_peak_info.at[index2, 'is_starting_event'] = False
                    df_peak_info.loc[index2+1:, 'is_starting_event'] = True
                    break
    
    # check if missed one peak in the bursts
    for index in range(len(df_peak_info)):
        if df_peak_info['is_ending_burst'][index]:
            index_ending_burst = index
            if index_ending_burst <= len(peak_indices)-3:
                post_distance = peak_indices[index_ending_burst+1] - peak_indices[index_ending_burst]
                post_post_distance = peak_indices[index_ending_burst+2] - peak_indices[index_ending_burst+1]
                pre_distance = peak_indices[index_ending_burst] - peak_indices[index_ending_burst-1]

                condition1 = post_distance < 1500
                condition2 = post_distance * 1.1 < post_post_distance
                if condition1 & condition2:
                    df_peak_info.at[index_ending_burst, 'is_starting_burst'] = False
                    df_peak_info.at[index_ending_burst+1, 'is_starting_burst'] = False
                    df_peak_info.at[index_ending_burst, 'is_ending_burst'] = False
                    df_peak_info.at[index_ending_burst+1, 'is_ending_burst'] = True
                    df_peak_info.at[index_ending_burst, 'is_in_burst'] = True
                    df_peak_info.at[index_ending_burst+1, 'is_in_burst'] = True
                    df_peak_info.at[index_ending_burst, 'is_starting_event'] = False
                    df_peak_info.at[index_ending_burst+1, 'is_starting_event'] = False
    
    # Re-adjust is_tonic
    for index in range(len(df_peak_info)):
        condition1 = df_peak_info['is_in_burst'][index]
        condition2 = df_peak_info['is_in_tonic'][index]
        if condition1 & condition2:
            df_peak_info['is_in_tonic'][index] = False

    ## Add peak frequency
    for index in range(len(df_peak_info)-1):
        this_peak_time = df_peak_info['peak_index'][index]*time_resolution
        next_peak_time = df_peak_info['peak_index'][index+1]*time_resolution
        df_peak_info.at[index,'frequency'] = 1/(next_peak_time-this_peak_time)
    
    ## Add burst_index
    burst_index = 0
    df_peak_info['burst_index'] = np.nan
    for index in range(len(df_peak_info)):
        if df_peak_info['is_starting_burst'][index]:
            burst_index += 1
        
        if df_peak_info['is_in_burst'][index]:
            df_peak_info.at[index, 'burst_index'] = burst_index
    
    return df_peak_info
