from modeller import *
from modeller.automodel import *    # Load the automodel class

log.verbose()
env = environ()

# directories for input atom files
env.io.atom_files_directory = ['.', '../atom_files']

class MyModel(automodel):
    def select_atoms(self):


a = MyModel(env, alnfile = '/home/german/labo/18/egfr/model/1XKK_A/to_model_1XKK_A',
            knowns = '1XKK_A', sequence = '1XKK_A_full')
a.starting_model= 1
a.ending_model  = 1

a.make()