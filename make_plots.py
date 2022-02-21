#!/bin/python

from tabulate import tabulate 
import pandas as pd
import matplotlib.pyplot as plt

create_times_table = open('create_times_md', 'w')
teardown_times_table = open('teardown_times_md', 'w')

if __name__ == "__main__":
    create_times = pd.read_csv("times.csv")
    create_times = create_times.pivot(
            index='Number of Pods',
            columns='Storage Class',
            values='Seconds')

    print(create_times.to_markdown(), file=create_times_table)
    create_times_table.close()
    
    plt.plot(create_times['csi-manila-default'], label='manila csi', marker='o')
    plt.plot(create_times['standard-csi'], label='cinder csi', marker='o')
    plt.plot(create_times['standard'], label='in-tree cinder', marker='o')
    plt.legend(title='Provisioners')
    plt.ylabel('seconds')
    plt.xlabel('pods/pvcs')
    plt.title('Provisioning Time at Scale')
    plt.grid()
    plt.savefig('provisioning_time.png')
    plt.close()

    teardown_times = pd.read_csv("teardown_times.csv")
    teardown_times = teardown_times.pivot(
            index='Number of Pods',
            columns='Storage Class',
            values='Seconds')
 
    print(teardown_times.to_markdown(), file=teardown_times_table)
    teardown_times_table.close()

    plt.plot(teardown_times['csi-manila-default'], label='manila csi', marker='o')
    plt.plot(teardown_times['standard-csi'], label='cinder csi', marker='o')
    plt.plot(teardown_times['standard'], label='in-tree cinder', marker='o')
    plt.legend(title='Provisioners')
    plt.xlabel('pods/pvcs')
    plt.ylabel('seconds')
    plt.title('Teardown Time at Scale')
    plt.grid()
    plt.savefig('teardown_time.png')
    plt.close()
