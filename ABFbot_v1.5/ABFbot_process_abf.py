import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pyabf
import sys
import os
import datetime
from scipy.signal import find_peaks
from scipy.signal import peak_widths
from scipy import optimize
from ABFbot_functions import *
from ABFbot_detect_bursts import *


def process_sweep(abf, sweep, file_first_name, output_dir, input_resistance):
    print('Analyze ' + file_first_name + '; sweep: ' + str(sweep+1))
    output = {
        'File': file_first_name,
        'Sweep': sweep+1,
        'IR': input_resistance,
        'Current Steps (pA)': np.nan,
        'RMP (mV)': np.nan,
        'Hyperpolarization amplitude (mV)': np.nan,
        '# Bursts': 0,
        '# Events': 0,
        '# Total AP': np.nan,
        '# LTS': np.nan,
        'Tonically firing': np.nan,
        'Tonic Frequency (Hz)': np.nan,
        'Burst Index': np.nan,
        'Latency (ms)': np.nan,
        'Duration (ms)': np.nan,
        'AP Freq (Hz)': np.nan,
        '# AP in this burst': np.nan,
        'AP Threshold (mV)': np.nan,
        'AHP (mV)': np.nan,           
        'IBI (ms)': np.nan,
        'Avg ISI of FIRST 3 spikes (ms)': np.nan,
        'Initial Frequency (Hz)': np.nan,
        'Avg ISI of LAST 3 spikes (ms)': np.nan,
        'Final epoch Frequency (Hz)': np.nan,
        'COMMENTS': np.nan
    }

    abf.setSweep(sweep)
    time = abf.sweepX
    time_resolution =  time[1]  
    voltage = abf.sweepY
    current = abf.sweepC
    voltage_derivative = get_derivative(voltage, x_unit_distance = time_resolution)

    i_start_resting, i_end_resting, resting_membrane_potential = get_resting_membrane_potential(voltage, current)
    
    i_start_hyperpolarized, i_start_calculate_hyperpolarized, i_end_hyperpolarized, hyperpolarized_potential = \
        get_hyperpolarized_potential(voltage, current, time_resolution)

    hyperpolarization_amplitude = hyperpolarized_potential - resting_membrane_potential

    output['RMP (mV)'] = resting_membrane_potential
    output['Hyperpolarization amplitude (mV)'] = hyperpolarization_amplitude
    output['Current Steps (pA)'] = current.min()

    # Peak Detection
    peak_indices, _ = find_peaks(voltage, height=-20, threshold=-40)
    peak_indices = np.array(peak_indices)
    num_total_ap = len(peak_indices)
    print('num_total_ap: ', num_total_ap)
    output['# Total AP'] = num_total_ap
        
    if num_total_ap > 1:
        if peak_indices[0] > i_end_hyperpolarized:
            df_peak_info = detect_bursts(peak_indices, time_resolution)
            # df_peak_info.to_csv(output_dir + '/' + file_first_name + '_sweep_' + str(sweep+1) + '_df_peak_info.csv')

            output['Tonic Frequency (Hz)'] = get_tonic_frequency(df_peak_info, time)

            # Burst Detection
            num_bursts = df_peak_info['is_starting_burst'].sum()
            num_events = df_peak_info['is_starting_event'].sum()
            output['# Bursts'] = num_bursts
            output['# Events'] = num_events
            if df_peak_info['is_in_tonic'].sum() > 0:
                output['Tonically firing'] = 'Yes'
                print("Tonic firing detected")
            else:
                output['Tonically firing'] = 'No'
                print("No tonic firing detected")

            if num_bursts > 0:
                df_output = pd.DataFrame()
                for burst_index in range(1, num_bursts+1):
                    burst_details = get_burst_details(df_peak_info, burst_index, time, voltage, voltage_derivative, current)
                    output['Burst Index'] = burst_index
                    output['Latency (ms)'] = burst_details['latency']
                    output['Duration (ms)'] = burst_details['burst_duration'] * 1000
                    output['AP Freq (Hz)'] = burst_details['ap_frequency_in_burst']
                    output['# AP in this burst'] = burst_details['num_ap_in_burst']
                    output['AP Threshold (mV)'] = burst_details['ap_threshold']
                    output['AHP (mV)'] = burst_details['ahp']
                    output['IBI (ms)'] = burst_details['ibi']
                    df_output_burst = pd.DataFrame(output, index=[0])
                    df_output = pd.concat([df_output, df_output_burst], ignore_index=True)
            else:
                df_output = pd.DataFrame(output, index=[0])
                return df_output
        else:
            df_output = pd.DataFrame(output, index=[0])
            return df_output
    else:
        df_output = pd.DataFrame(output, index=[0])
        return df_output

    return df_output


def plot_sweep(abf, sweep, file_first_name, output_dir):
    print('Plot ' + file_first_name + '; sweep: ' + str(sweep+1))
    abf.setSweep(sweep)
    time = abf.sweepX
    time_resolution =  time[1]  
    voltage = abf.sweepY
    current = abf.sweepC
    voltage_derivative = get_derivative(voltage, x_unit_distance = time_resolution)

    i_start_resting, i_end_resting, resting_membrane_potential = get_resting_membrane_potential(voltage, current)
    
    i_start_hyperpolarized, i_start_calculate_hyperpolarized, i_end_hyperpolarized, hyperpolarized_potential = \
        get_hyperpolarized_potential(voltage, current, time_resolution)

    peak_indices, _ = find_peaks(voltage, height=-20, threshold=-40)
    peak_indices = np.array(peak_indices)
    num_total_ap = len(peak_indices)
    
    test_time_range = [0,time[-1]]
    fig, ax = plt.subplots(nrows = 4, ncols=1, figsize=(120,20))
    ax[0].set_ylabel('Voltage (mV)')
    ax[0].set_title('Voltage (mV)', size=50)
    ax[1].set_ylabel('Derivative of Voltage (mV/s)')
    ax[1].set_title('Derivative of Voltage (mV/s)', size=50)
    ax[2].set_ylabel('Current (pA)')
    ax[2].set_title('Current (pA)', size=50)
    ax[3].set_ylabel('Voltage (mV)')
    ax[3].set_title('Voltage (mV) Zoomed-in', size=50)
    
    ax[0].plot(time, voltage)
    ax[1].plot(time[:-1], voltage_derivative, '.')
    ax[2].plot(time, current)
    ax[3].plot(time, voltage, '.')

    for x_index in range(i_start_resting, i_end_resting+1):
        ax[0].vlines(x = time[x_index], ymin=-140, ymax=30, color='cyan', zorder=0)
    
    for x_index in range(i_start_calculate_hyperpolarized, i_end_hyperpolarized+1):
        ax[0].vlines(x = time[x_index], ymin=-140, ymax=30, color='cyan', zorder=0)

    points_to_plot = [
        i_start_resting,
        i_end_resting,
        i_start_hyperpolarized,
        i_start_calculate_hyperpolarized,
        i_end_hyperpolarized
    ]

    ax[0].plot(time[points_to_plot], voltage[points_to_plot], '.', color='purple')
    ax[1].plot(time[points_to_plot], voltage_derivative[points_to_plot], '.', color='purple')
    ax[2].plot(time[points_to_plot], current[points_to_plot], '.', color='purple')
    ax[3].plot(time[points_to_plot], voltage[points_to_plot], '.', color='purple')
    
    ax[0].plot(time[peak_indices], voltage[peak_indices], '.', color='red')
    ax[3].plot(time[peak_indices], voltage[peak_indices], '.', color='red')

    if num_total_ap > 1:
        if peak_indices[0] < i_end_hyperpolarized:
            ax[0].set_title('Action Potential during holding', size=50, color='red')
        else:
            df_peak_info = detect_bursts(peak_indices, time_resolution)
            
            # Label Peak Frequencies
            peak_frequency_array = df_peak_info['frequency']
            for index in range(len(peak_indices)-1):
                if peak_frequency_array[index] < 100:
                    ax[0].text(
                        time[peak_indices[index]],
                        voltage[peak_indices[index]] + 2 ,
                        "{:.1f}".format(peak_frequency_array[index]),
                        color='brown', size=7
                    )
                    # ax[3].text(
                    #     time[peak_indices[index]],
                    #     voltage[peak_indices[index]] + 5,
                    #     "{:.2f}".format(peak_frequency_array[index]) + 'Hz',
                    #     color='brown'
                    # )
            
            # Tonic firing detection
            tonic_true_indicies = df_peak_info['peak_index'][df_peak_info['is_in_tonic'] == True]
            if len(tonic_true_indicies) > 0:
                for tonic_true_index in tonic_true_indicies:
                    ax[0].plot(
                        time[tonic_true_index], 35, "s",
                        color = 'orange', markersize = 30
                    )

            # Burst Detection
            num_bursts = df_peak_info['is_starting_burst'].sum()
            num_events = df_peak_info['is_starting_event'].sum()

            if num_bursts > 0:
                df_output = pd.DataFrame()
                for burst_index in range(1, num_bursts+1):
                    burst_details = get_burst_details(df_peak_info, burst_index, time, voltage, voltage_derivative, current)
                    i_first_peak = burst_details['i_first_peak']
                    i_last_peak = burst_details['i_last_peak']
                    i_ap_threshold = burst_details['i_ap_threshold']
                    i_repolar_peak = burst_details['i_repolar_peak']
                    i_post_repolar_bottom = burst_details['i_post_repolar_bottom']

                    for x_index in range(i_first_peak, i_last_peak):
                        ax[0].vlines(x = time[x_index], ymin=-120, ymax=30, color='yellow', zorder=0)
                        ax[1].vlines(x = time[x_index], ymin=voltage_derivative.min(), ymax=voltage_derivative.max(), color='yellow', linewidth=3,zorder=0)
                        ax[3].vlines(x = time[x_index], ymin=-120, ymax=30, color='yellow', linewidth=3,zorder=0)
                    
                    points_to_plot = [
                        i_ap_threshold,
                        i_repolar_peak,
                        i_post_repolar_bottom
                    ]

                    points_to_plot = [e for e in points_to_plot if e]

                    print(points_to_plot)

                    ax[0].plot(
                        time[points_to_plot], voltage[points_to_plot], '.', color='orange'
                    )
                    ax[1].plot(
                        time[i_ap_threshold], voltage_derivative[i_ap_threshold], '.', color='orange'
                    )
                    ax[3].plot(
                        time[points_to_plot], voltage[points_to_plot], '.', markersize=10, color='darkorange'
                    )


    ax[0].set_xlim(test_time_range[0], test_time_range[1])
    ax[1].set_xlim(test_time_range[0], test_time_range[1])
    ax[2].set_xlim(test_time_range[0], test_time_range[1])

    try:
        i_first_peak = peak_indices[0]
        ax[1].set_xlim(time[i_first_peak-300], time[i_first_peak+2700])
        ax[3].set_xlim(time[i_first_peak-300], time[i_first_peak+2700])
    except:
        print('No peak detected')

    plt.tight_layout()
    fig.savefig(output_dir + '/trace_' + file_first_name + '_' + str(sweep+1) + '.png')
    plt.close()


def process_abf(filepath, df, output_dir):
    file_first_name = filepath.split('/')[-1].split('.')[0]
    abf = pyabf.ABF(filepath)
    input_resistance = get_input_resistance(abf)
    
    for sweep in range(abf.sweepCount):
        df_output = process_sweep(abf, sweep, file_first_name, output_dir, input_resistance)
        df = pd.concat([df, df_output], ignore_index=True)
        plot_sweep(abf, sweep, file_first_name, output_dir)

    return df

