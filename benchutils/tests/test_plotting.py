import unittest

from benchutils import plotting


# TODO test errors (blocked by checking errors in plotting.py)
class TestMetricComparisonPlot(unittest.TestCase):
    # TODO get test filepaths with some more sophisticated way for demo data
    #  and run it on them, and keep track of files to delete after running
    #  unit tests
    def test_runs_metric_comparison_plot(self):
        plotting.metric_comparison_plot('benchutils/tests/data/summaries/'
                                        '2019.08.07_10.20.59_sample_0.genus'
                                        '.absolute_error.txt',
                                        'benchutils/tests/data/summaries/'
                                        '2019.08.07_10.20.59_sample_0.genus'
                                        '.correlation.txt',
                                        'benchutils/tests/data/summaries/'
                                        'test_metric_plot.svg')


# TODO test errors (blocked by checking errors in plotting.py)
class TestMethodComparisonPlot(unittest.TestCase):
    # TODO refactor with more sophisticated file path getters
    def test_runs_method_comparison_plot(self):
        plotting.method_comparison_plot(['benchutils/tests/data/summaries/'
                                         '2019.08.07_10.20.59_sample_0.genus'
                                         '.correlation.txt',
                                         'benchutils/tests/data/summaries/'
                                         '2019.08.07_10.20.59_sample_1.genus'
                                         '.correlation.txt'],
                                        'benchutils/tests/data/summaries/'
                                        'test_method_plot.svg')


if __name__ == '__main__':
    unittest.main()
