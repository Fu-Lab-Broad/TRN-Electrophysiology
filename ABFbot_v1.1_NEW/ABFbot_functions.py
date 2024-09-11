import numpy as np
import pandas as pd
from scipy import optimize

def get_resting_membrane_potential(voltage, current):
    voltage = np.array(voltage)
    current = np.array(current)
    index_end_resting = None
    
    for index in range(5000):
        current_difference = current[index+1] - current[index]
        # print(str(index) + ' current_difference: ', current_difference)
        if (current_difference < -10) | (index == 4999):
            resting_membrane_potential = voltage[index-250:index-200].mean()
            return index-250, index-200, resting_membrane_potential


def get_post_bottom(array, start_index, num_neighbors = 100):
    for index in range(start_index, len(array)):
        neighbor_after_indicies = index + np.array(list(range(1, num_neighbors+1)))
        difference = array[neighbor_after_indicies] - array[index]
        if np.all(difference >= 0):
            return index


def get_index_sharp_increase(array, start_index, end_index=None, threshold=0, num_neighbors=100):
    if end_index == None:
        end_index = len(array)
    for index in range(start_index, end_index):
        neighbor_after_indicies = index + np.array(list(range(1, num_neighbors+1)))
        difference = array[neighbor_after_indicies] - array[index]
        if np.all(difference >= threshold):
            return index


def get_index_sharp_decrease(array, start_index, end_index=None, threshold=0, num_neighbors = 100):
    if end_index == None:
        end_index = len(array)
    for index in range(start_index, end_index):
        neighbor_after_indicies = index + np.array(list(range(1, num_neighbors+1)))
        difference = array[neighbor_after_indicies] - array[index]
        if np.all(difference <= threshold):
            return index
    return None


def get_hyperpolarized_potential(voltage, current, time_resolution):

    voltage = np.array(voltage)
    index_start_hyperpolarized = get_index_sharp_decrease(current, start_index = 0, end_index=int(7000 * (0.0001/time_resolution)), threshold = -10, num_neighbors = 1)
    if index_start_hyperpolarized == None:
        index_start_hyperpolarized = 5000
    index_end_hyperpolarized = get_index_sharp_increase(current, start_index = 0, end_index=int(10000 * (0.0001/time_resolution)), threshold = 10, num_neighbors = 1)
    if index_end_hyperpolarized == None:
        index_end_hyperpolarized = 5500
    index_start_calculate_hyperpolarized = index_end_hyperpolarized - 500
    hyperpolarized_potential = voltage[index_start_calculate_hyperpolarized:index_end_hyperpolarized].mean()
    return index_start_hyperpolarized, index_start_calculate_hyperpolarized, index_end_hyperpolarized, hyperpolarized_potential


def get_burst_details(df_peak_info, burst_index, time, voltage, voltage_derivative, current):
    df_this_burst = df_peak_info[df_peak_info['burst_index'] == burst_index]
    num_ap_in_burst = len(df_this_burst)
    i_first_peak = df_this_burst['peak_index'].values[0]
    i_last_peak = df_this_burst['peak_index'].values[-1]
    burst_duration = time[i_last_peak] - time[i_first_peak]
    ap_frequency_in_burst = (num_ap_in_burst-1)/burst_duration

    i_ap_threshold = get_peak_threshold_index(voltage, voltage_derivative, i_first_peak)
    ap_threshold = voltage[i_ap_threshold]

    time_resolution = time[1]
    _, _, i_end_hyperpolarized, _ = \
        get_hyperpolarized_potential(voltage, current, time_resolution)

    latency = (time[i_ap_threshold] - time[i_end_hyperpolarized]) * 1000

    i_repolar_peak = get_repolar_peak_index(voltage, i_last_peak)        
    i_post_repolar_bottom = get_index_sharp_increase(voltage, start_index = i_repolar_peak, threshold=0, num_neighbors = 500)
    ahp = voltage[i_repolar_peak] - voltage[i_post_repolar_bottom]

    num_bursts = df_peak_info['is_starting_burst'].sum()
    if num_bursts > burst_index:
        df_next_burst = df_peak_info[df_peak_info['burst_index'] == (burst_index+1)]
        i_peak1_next_burst = df_next_burst['peak_index'].values[0]
        i_next_ap_threshold = get_peak_threshold_index(voltage, voltage_derivative, i_peak1_next_burst)
        ibi = (time[i_next_ap_threshold] - time[i_repolar_peak]) * 1000
    else:
        ibi = np.nan

    output = {
        'num_ap_in_burst': num_ap_in_burst,
        'burst_duration': burst_duration,
        'ap_frequency_in_burst': ap_frequency_in_burst,
        'ap_threshold': ap_threshold,
        'latency': latency,
        'ahp': ahp,
        'ibi': ibi,
        'i_first_peak': i_first_peak,
        'i_last_peak': i_last_peak,
        'i_ap_threshold': i_ap_threshold,
        'i_repolar_peak': i_repolar_peak,
        'i_post_repolar_bottom': i_post_repolar_bottom
    }
    return output


def get_tonic_frequency(df_peak_info, time):
    time_resolution = time[1]
    df_tonic = df_peak_info[df_peak_info['is_in_tonic']]
    if len(df_tonic)>0:
        i_tonic_start = df_tonic['peak_index'].values[0]
        i_tonic_end = df_tonic['peak_index'].values[-1]
        tonic_duration = time[i_tonic_end] - time[i_tonic_start]
        num_ap = len(df_tonic)
        tonic_frequency = (num_ap-1)/tonic_duration
    else:
        tonic_frequency = np.nan
    
    return tonic_frequency



def get_peak_threshold_index(voltage, voltage_derivative, peak_index):
    for index in range(peak_index, 0, -1):
        condition1 = voltage_derivative[index] < voltage_derivative[index+1]
        condition2 = voltage_derivative[index] < voltage_derivative.max() * 0.2
        if condition1 & condition2:
            return index
    return index


def get_peak_ending_index(voltage, voltage_derivative, peak_index):
    for index in range(peak_index, len(voltage), 1):
        if voltage_derivative[index] > 0:
            return index-1


def get_repolar_peak_index(voltage, i_burst_end):
    start_index = i_burst_end + 20
    end_index = i_burst_end + 500
    repolar_peak_index = np.argmax(voltage[start_index:end_index]) + start_index
    return repolar_peak_index


def func_linear(current, resistance, b):
    voltage = current * resistance + b
    return voltage


def get_input_resistance(abf):
    input_resistance_v_list = []
    input_resistance_i_list = []
    if abf.sweepCount >= 2:
        for sweep in range(abf.sweepCount):
            abf.setSweep(sweep)
            time = abf.sweepX
            time_resolution =  time[1]
            voltage = abf.sweepY
            current = abf.sweepC
            index_start_resting, index_end_resting, resting_membrane_potential = get_resting_membrane_potential(voltage, current)
            index_start_hyperpolarized, index_start_calculate_hyperpolarized, index_end_hyperpolarized, hyperpolarized_potential = get_hyperpolarized_potential(voltage, current, time_resolution)
            index_middle_hyperpolarized = (index_start_hyperpolarized + index_end_hyperpolarized)//2
            index_middle_left_hyperpolarized = index_middle_hyperpolarized - 1000
            index_middle_right_hyperpolarized = index_middle_hyperpolarized + 1000
            hyperpolarization_amplitude = hyperpolarized_potential - resting_membrane_potential
            input_resistance_v_list.append(voltage[index_middle_left_hyperpolarized])
            input_resistance_v_list.append(voltage[index_middle_hyperpolarized])
            input_resistance_v_list.append(voltage[index_middle_right_hyperpolarized])
            input_resistance_i_list.append(abf.sweepC[index_middle_left_hyperpolarized])
            input_resistance_i_list.append(abf.sweepC[index_middle_hyperpolarized])
            input_resistance_i_list.append(abf.sweepC[index_middle_right_hyperpolarized])
    
        input_resistance, b = optimize.curve_fit(func_linear, input_resistance_i_list, input_resistance_v_list)[0]
        input_resistance = input_resistance * 1000
    else:
        input_resistance = np.nan

    return input_resistance


def get_derivative(array, x_unit_distance):
    array_derivative = np.zeros(len(array)-1)
    for index in range(len(array_derivative)):
        array_derivative[index] = (array[index+1] - array[index])/x_unit_distance
    return array_derivative


