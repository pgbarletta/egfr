from modeller import *
from modeller.automodel import *    # Load the automodel class

log.verbose()
env = environ()

# directories for input atom files
env.io.atom_files_directory = ['.', '../atom_files']

class MyModel(automodel):
	def select_atoms(self):
		return selection(self.residue_range('1', '3'),
			self.residue_range('164', '174'),)


a = MyModel(env, alnfile = '/home/german/labo/18/egfr/model/5CNN_B/to_model_5CNN_B',
            knowns = '5CNN_B', sequence = '5CNN_B_full')
a.starting_model= 1
a.ending_model  = 50

a.make()
